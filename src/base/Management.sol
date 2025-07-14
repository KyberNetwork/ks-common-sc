// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Common} from 'src/base/Common.sol';

import {IManagement} from 'src/interfaces/IManagement.sol';
import {KSRoles} from 'src/libraries/KSRoles.sol';
import {TokenHelper} from 'src/libraries/token/TokenHelper.sol';

import {AccessControlDefaultAdminRules} from
  'openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol';
import {IERC1155} from 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';
import {Pausable} from 'openzeppelin-contracts/contracts/utils/Pausable.sol';

contract Management is AccessControlDefaultAdminRules, Pausable, Common, IManagement {
  using TokenHelper for address;

  modifier onlyRoleOrDefaultAdmin(bytes32 role) {
    if (!hasRole(role, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert AccessControlUnauthorizedAccount(_msgSender(), role);
    }
    _;
  }

  constructor(uint48 initialDelay, address initialAdmin)
    AccessControlDefaultAdminRules(initialDelay, initialAdmin)
  {}

  // ================================
  // ===== Role Management ==========
  // ================================

  /// @inheritdoc IManagement
  function transferOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
  }

  /// @inheritdoc IManagement
  function batchGrantRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchGrantRole(role, accounts);
  }

  /// @dev See {batchGrantRole}
  /// Internal function without access restriction.
  function _batchGrantRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  /// @inheritdoc IManagement
  function batchRevokeRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchRevokeRole(role, accounts);
  }

  /// @dev See {batchRevokeRole}
  /// Internal function without access restriction.
  function _batchRevokeRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _revokeRole(role, accounts[i]);
    }
  }

  // ================================
  // ===== Pause functionality ======
  // ================================

  /// @inheritdoc IManagement
  function pause() external onlyRoleOrDefaultAdmin(KSRoles.GUARDIAN_ROLE) {
    _pause();
  }

  /// @inheritdoc IManagement
  function unpause() external onlyRoleOrDefaultAdmin(KSRoles.GUARDIAN_ROLE) {
    _unpause();
  }

  // ================================
  // ===== Rescue functionality =====
  // ================================

  /// @inheritdoc IManagement
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

  /// @inheritdoc IManagement
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

  /// @inheritdoc IManagement
  function rescueERC1155s(
    IERC1155[] calldata tokens,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address recipient
  )
    external
    onlyRoleOrDefaultAdmin(KSRoles.RESCUER_ROLE)
    checkAddress(recipient)
    checkLengths(tokens.length, tokenIds.length)
    checkLengths(tokens.length, amounts.length)
  {
    for (uint256 i = 0; i < tokens.length; i++) {
      _transferERC1155(tokens[i], tokenIds[i], amounts[i], recipient);
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

  function _transferERC1155(IERC1155 token, uint256 tokenId, uint256 amount, address recipient)
    internal
  {
    if (amount == 0) {
      amount = token.balanceOf(address(this), tokenId);
    }
    token.safeTransferFrom(address(this), recipient, tokenId, amount, '');
  }
}
