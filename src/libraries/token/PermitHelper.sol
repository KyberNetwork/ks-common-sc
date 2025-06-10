// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';

import '../CustomRevert.sol';
import '../calldata/CalldataDecoder.sol';

import 'src/interfaces/IDaiLikePermit.sol';
import 'src/interfaces/IPermit2.sol';

library PermitHelper {
  using CalldataDecoder for bytes;

  /// @notice Additional context for ERC-7751 wrapped error when permit fails
  error PermitFailed();

  /// @notice Additional context for ERC-7751 wrapped error when permit2 fails
  error Permit2Failed();

  function permit(address token, bytes calldata data) internal returns (bool success) {
    if (data.length == 32 * 5) {
      success = _callPermit(token, IERC20Permit.permit.selector, data);
    } else if (data.length == 32 * 6) {
      success = _callPermit(token, IDaiLikePermit.permit.selector, data);
    } else {
      return false;
    }
  }

  function permit2(address token, bytes calldata data) internal returns (bool success) {
    if (data.length <= 32 * 6) {
      return false;
    }

    IPermit2.PermitSingle calldata permitSingle;
    assembly {
      permitSingle := data.offset
    }
    bytes calldata signature = data.decodeBytes(6);
    (success,) = token.call(abi.encodeCall(IPermit2.permit, (msg.sender, permitSingle, signature)));

    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(token, IPermit2.permit.selector, Permit2Failed.selector);
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
