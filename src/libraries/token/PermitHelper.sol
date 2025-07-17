// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Permit} from
  'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {IDaiLikePermit} from 'src/interfaces/IDaiLikePermit.sol';
import {IERC721Permit_v3} from 'src/interfaces/IERC721Permit_v3.sol';
import {IERC721Permit_v4} from 'src/interfaces/IERC721Permit_v4.sol';
import {CustomRevert} from 'src/libraries/CustomRevert.sol';
import {CalldataDecoder} from 'src/libraries/calldata/CalldataDecoder.sol';

library PermitHelper {
  using CalldataDecoder for bytes;

  /// @notice Additional context for ERC-7751 wrapped error when permit fails
  error ERC20PermitFailed();
  error ERC721PermitFailed();

  function erc20Permit(address token, address owner, bytes calldata permitData)
    internal
    returns (bool success)
  {
    if (permitData.length == 32 * 5) {
      success = _callErc20Permit(token, owner, IERC20Permit.permit.selector, permitData);
    } else if (permitData.length == 32 * 6) {
      success = _callErc20Permit(token, owner, IDaiLikePermit.permit.selector, permitData);
    } else {
      return false;
    }
  }

  function erc721Permit(address token, uint256 tokenId, bytes calldata permitData)
    internal
    returns (bool success)
  {
    if (permitData.length == 32 * 4) {
      success = _callErc721Permit(token, tokenId, IERC721Permit_v3.permit.selector, permitData, 0);
    } else if (permitData.length == 32 * 7) {
      success =
        _callErc721Permit(token, tokenId, IERC721Permit_v4.permit.selector, permitData, 0xa0);
    } else {
      return false;
    }
  }

  function _callErc721Permit(
    address token,
    uint256 tokenId,
    bytes4 selector,
    bytes calldata permitData,
    uint256 overrideSigOffset
  ) internal returns (bool success) {
    bytes memory data = new bytes(4 + 32 * 2 + permitData.length);
    assembly ("memory-safe") {
      mstore(add(data, 0x20), selector)
      mstore(add(data, 0x24), address())
      mstore(add(data, 0x44), tokenId)
      calldatacopy(add(data, 0x64), permitData.offset, permitData.length)
      // override the signature offset in case dynamic bytes (65 bytes length)
      if overrideSigOffset { mstore(add(data, add(overrideSigOffset, 4)), overrideSigOffset) }
      success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0)
    }

    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(token, selector, ERC721PermitFailed.selector);
    }
  }

  function _callErc20Permit(
    address token,
    address owner,
    bytes4 selector,
    bytes calldata permitData
  ) internal returns (bool success) {
    bytes memory data = new bytes(4 + 32 * 2 + permitData.length);
    assembly ("memory-safe") {
      mstore(add(data, 0x20), selector)
      mstore(add(data, 0x24), owner)
      mstore(add(data, 0x44), address())
      calldatacopy(add(data, 0x64), permitData.offset, permitData.length)
      success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0)
    }

    if (!success) {
      CustomRevert.bubbleUpAndRevertWith(token, selector, ERC20PermitFailed.selector);
    }
  }
}
