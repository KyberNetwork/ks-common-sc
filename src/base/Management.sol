// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {KSRoles} from 'src/libraries/KSRoles.sol';

import {AccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';
import {Pausable} from 'openzeppelin-contracts/contracts/utils/Pausable.sol';

abstract contract Management is AccessControl, Pausable {
  constructor(address defaultAdmin) {
    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
  }

  function batchGrantRole(bytes32 role, address[] calldata accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  function batchRevokeRole(bytes32 role, address[] calldata accounts)
    external
    onlyRole(getRoleAdmin(role))
  {
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
