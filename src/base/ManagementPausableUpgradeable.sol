// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IManagementPausable} from '../interfaces/IManagementPausable.sol';

import {KSRoles} from '../libraries/KSRoles.sol';
import {ManagementBaseUpgradeable} from './ManagementBaseUpgradeable.sol';

import {
  PausableUpgradeable
} from 'openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol';

abstract contract ManagementPausableUpgradeable is
  ManagementBaseUpgradeable,
  IManagementPausable,
  PausableUpgradeable
{
  constructor() {
    _disableInitializers();
  }

  function initialize(address[] memory initialGuardians) public initializer {
    __ManagementPausable_init(initialGuardians);
  }

  function __ManagementPausable_init(address[] memory initialGuardians) internal onlyInitializing {
    _batchGrantRole(KSRoles.GUARDIAN_ROLE, initialGuardians);
  }

  /// @inheritdoc IManagementPausable
  function pause() external onlyRoleOrDefaultAdmin(KSRoles.GUARDIAN_ROLE) {
    _pause();
  }

  /// @inheritdoc IManagementPausable
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }
}
