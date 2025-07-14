// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CustomRevert} from 'src/libraries/CustomRevert.sol';
import {CalldataDecoder} from 'src/libraries/calldata/CalldataDecoder.sol';

import {IERC20Permit} from
  'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IDaiLikePermit} from 'src/interfaces/IDaiLikePermit.sol';

library PermitHelper {
  using CalldataDecoder for bytes;

  /// @notice Additional context for ERC-7751 wrapped error when permit fails
  error PermitFailed();

  function permit(address token, bytes calldata permitData) internal returns (bool success) {
    if (permitData.length == 32 * 5) {
      success = _callPermit(token, IERC20Permit.permit.selector, permitData);
    } else if (permitData.length == 32 * 6) {
      success = _callPermit(token, IDaiLikePermit.permit.selector, permitData);
    } else {
      return false;
    }
  }

  function _callPermit(address token, bytes4 selector, bytes calldata permitData)
    internal
    returns (bool success)
  {
    bytes memory data = new bytes(4 + 32 * 2 + permitData.length);
    assembly ("memory-safe") {
      mstore(add(data, 0x20), selector)
      mstore(add(data, 0x24), caller())
      mstore(add(data, 0x44), address())
      calldatacopy(add(data, 0x64), permitData.offset, permitData.length)
      success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0)
    }

    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(token, selector, PermitFailed.selector);
    }
  }
}
