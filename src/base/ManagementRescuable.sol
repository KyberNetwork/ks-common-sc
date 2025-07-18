// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IManagementRescuable} from '../interfaces/IManagementRescuable.sol';

import {KSRoles} from '../libraries/KSRoles.sol';
import {TokenHelper} from '../libraries/token/TokenHelper.sol';
import {ManagementBase} from './ManagementBase.sol';

import {IERC1155} from 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

abstract contract ManagementRescuable is ManagementBase, IManagementRescuable {
  using TokenHelper for address;

  /// @inheritdoc IManagementRescuable
  function rescueERC20s(address[] calldata tokens, uint256[] memory amounts, address recipient)
    external
    onlyRoleOrDefaultAdmin(KSRoles.RESCUER_ROLE)
    checkAddress(recipient)
    checkLengths(tokens.length, amounts.length)
  {
    for (uint256 i = 0; i < tokens.length; i++) {
      amounts[i] = _transferERC20(tokens[i], amounts[i], recipient);
    }

    emit RescueERC20s(tokens, amounts, recipient);
  }

  /// @inheritdoc IManagementRescuable
  function rescueERC721s(IERC721[] calldata tokens, uint256[] calldata tokenIds, address recipient)
    external
    onlyRoleOrDefaultAdmin(KSRoles.RESCUER_ROLE)
    checkAddress(recipient)
    checkLengths(tokens.length, tokenIds.length)
  {
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i].safeTransferFrom(address(this), recipient, tokenIds[i]);
    }

    emit RescueERC721s(tokens, tokenIds, recipient);
  }

  /// @inheritdoc IManagementRescuable
  function rescueERC1155s(
    IERC1155[] calldata tokens,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes[] calldata datas,
    address recipient
  )
    external
    onlyRoleOrDefaultAdmin(KSRoles.RESCUER_ROLE)
    checkAddress(recipient)
    checkLengths(tokens.length, tokenIds.length)
    checkLengths(tokens.length, amounts.length)
    checkLengths(tokens.length, datas.length)
  {
    for (uint256 i = 0; i < tokens.length; i++) {
      _transferERC1155(tokens[i], tokenIds[i], amounts[i], datas[i], recipient);
    }

    emit RescueERC1155s(tokens, tokenIds, amounts, recipient);
  }

  function _transferERC20(address token, uint256 amount, address recipient)
    internal
    returns (uint256)
  {
    if (amount == 0) {
      amount = token.balanceOf(address(this));
    }
    token.safeTransfer(recipient, amount);

    return amount;
  }

  function _transferERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 amount,
    bytes memory data,
    address recipient
  ) internal {
    if (amount == 0) {
      amount = token.balanceOf(address(this), tokenId);
    }
    token.safeTransferFrom(address(this), recipient, tokenId, amount, data);
  }
}
