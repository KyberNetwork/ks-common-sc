// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';

import '../CustomRevert.sol';
import '../calldata/CalldataDecoder.sol';

import 'src/interfaces/IDaiLikePermit.sol';
import 'src/interfaces/IPermit2.sol';

/// @title Library for permit and permit2
library PermitHelper {
  using CalldataDecoder for bytes;

  /// @notice Additional context for ERC-7751 wrapped error when permit fails
  error PermitFailed();

  /// @notice Additional context for ERC-7751 wrapped error when permit2 fails
  error Permit2Failed();

  function permit(address token, bytes calldata data) internal returns (bool success) {
    if (data.length == 32 * 5) {
      (success,) = token.call(
        abi.encodeWithSelector(IERC20Permit.permit.selector, msg.sender, address(this), data)
      );

      if (!success) {
        CustomRevert.bubbleUpAndRevertWith(
          token, IERC20Permit.permit.selector, PermitFailed.selector
        );
      }
    } else if (data.length == 32 * 6) {
      (success,) = token.call(
        abi.encodeWithSelector(IDaiLikePermit.permit.selector, msg.sender, address(this), data)
      );

      if (!success) {
        CustomRevert.bubbleUpAndRevertWith(
          token, IDaiLikePermit.permit.selector, PermitFailed.selector
        );
      }
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
    (success,) = token.call(
      abi.encodeWithSelector(IPermit2.permit.selector, msg.sender, permitSingle, signature)
    );

    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(token, IPermit2.permit.selector, Permit2Failed.selector);
    }
  }
}
