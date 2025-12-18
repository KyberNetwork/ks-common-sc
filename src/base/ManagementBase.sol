// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Common} from './Common.sol';

import {IManagementBase} from '../interfaces/IManagementBase.sol';

import {
  AccessControlDefaultAdminRules
} from 'openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol';

contract ManagementBase is AccessControlDefaultAdminRules, Common, IManagementBase {
  /// @inheritdoc IManagementBase
  mapping(bytes32 role => bytes32 roleRevoker) public roleRevokers;

  constructor(uint48 initialDelay, address initialAdmin)
    AccessControlDefaultAdminRules(initialDelay, initialAdmin)
  {}

  /// @notice Modifier that checks if the sender is either the given role or the default admin role
  modifier onlyRoleOrDefaultAdmin(bytes32 role) {
    if (!hasRole(role, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      bytes32[] memory neededRoles = new bytes32[](2);
      neededRoles[0] = role;
      neededRoles[1] = DEFAULT_ADMIN_ROLE;
      revert ManagementUnauthorizedAccount(_msgSender(), neededRoles);
    }
    _;
  }

  /// @inheritdoc IManagementBase
  function transferOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
  }

  /// @inheritdoc IManagementBase
  function batchGrantRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchGrantRole(role, accounts);
  }

  /// @inheritdoc IManagementBase
  function batchRevokeRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchRevokeRole(role, accounts);
  }

  /// @inheritdoc IManagementBase
  function setRoleRevoker(bytes32 role, bytes32 roleRevoker) external onlyRole(getRoleAdmin(role)) {
    _setRoleRevoker(role, roleRevoker);
  }

  /// @notice Allows a role to be revoked by its revoker role
  function revokeRole(bytes32 role, address account) public override {
    bytes32[] memory neededRoles = new bytes32[](2);
    neededRoles[0] = roleRevokers[role];
    neededRoles[1] = getRoleAdmin(role);

    if (!hasRole(neededRoles[0], _msgSender()) && !hasRole(neededRoles[1], _msgSender())) {
      revert ManagementUnauthorizedAccount(_msgSender(), neededRoles);
    }

    _revokeRole(role, account);
  }

  /// @dev See {batchGrantRole}
  /// Internal function without access restriction.
  function _batchGrantRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  /// @dev See {batchRevokeRole}
  /// Internal function without access restriction.
  function _batchRevokeRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _revokeRole(role, accounts[i]);
    }
  }

  function _setRoleRevoker(bytes32 role, bytes32 roleRevoker) internal {
    bytes32 previousRoleRevoker = roleRevokers[role];
    roleRevokers[role] = roleRevoker;
    emit RoleRevokerChanged(role, previousRoleRevoker, roleRevoker);
  }
}
