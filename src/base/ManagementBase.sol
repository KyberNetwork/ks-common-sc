// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Common} from './Common.sol';

import {IManagementBase} from '../interfaces/IManagementBase.sol';

import {AccessControlDefaultAdminRules} from
  'openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol';

contract ManagementBase is AccessControlDefaultAdminRules, Common, IManagementBase {
  modifier onlyRoleOrDefaultAdmin(bytes32 role) {
    if (!hasRole(role, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert AccessControlUnauthorizedAccount(_msgSender(), role);
    }
    _;
  }

  constructor(uint48 initialDelay, address initialAdmin)
    AccessControlDefaultAdminRules(initialDelay, initialAdmin)
  {}

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

  /// @dev See {batchGrantRole}
  /// Internal function without access restriction.
  function _batchGrantRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  /// @inheritdoc IManagementBase
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
}
