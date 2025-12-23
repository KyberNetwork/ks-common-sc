// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IManagementPausable} from '../interfaces/IManagementPausable.sol';

import {KSRoles} from '../libraries/KSRoles.sol';
import {ManagementBase} from './ManagementBase.sol';

import {Pausable} from 'openzeppelin-contracts/contracts/utils/Pausable.sol';

abstract contract ManagementPausable is ManagementBase, IManagementPausable, Pausable {
  constructor(address[] memory initialGuardians) {
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
