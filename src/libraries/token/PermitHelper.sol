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

  function permit(address token, bytes calldata permitData) internal returns (bool success) {
    if (permitData.length == 32 * 5) {
      success = _callPermit(token, IERC20Permit.permit.selector, permitData);
    } else if (permitData.length == 32 * 6) {
      success = _callPermit(token, IDaiLikePermit.permit.selector, permitData);
    } else {
      return false;
    }
  }

  function permit2(IPermit2 _permit2, address token, bytes calldata permitData)
    internal
    returns (bool success)
  {
    if (permitData.length <= 32 * 6) {
      return false;
    }

    IPermit2.PermitSingle calldata permitSingle;
    assembly {
      permitSingle := permitData.offset
    }
    bytes calldata signature = permitData.decodeBytes(6);

    bytes memory data = abi.encodeCall(IPermit2.permit, (msg.sender, permitSingle, signature));
    assembly ("memory-safe") {
      success := call(gas(), _permit2, 0, add(data, 0x20), mload(data), 0, 0)
    }

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
