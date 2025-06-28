// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {KSRoles} from 'src/libraries/KSRoles.sol';

import {AccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';
import {Pausable} from 'openzeppelin-contracts/contracts/utils/Pausable.sol';

abstract contract Management is AccessControl, Pausable {
  constructor(address defaultAdmin) {
    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
  }

  /// @notice Batch grant roles to multiple accounts
  /// @param role The role to grant
  /// @param accounts The accounts to grant the role to
  function batchGrantRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchGrantRole(role, accounts);
  }

  function _batchGrantRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  /// @notice Batch revoke roles from multiple accounts
  /// @param role The role to revoke
  /// @param accounts The accounts to revoke the role from
  function batchRevokeRole(bytes32 role, address[] memory accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    _batchRevokeRole(role, accounts);
  }

  function _batchRevokeRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _revokeRole(role, accounts[i]);
    }
  }

  function pause() external onlyRole(KSRoles.GUARDIAN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(KSRoles.GUARDIAN_ROLE) {
    _unpause();
  }
}
