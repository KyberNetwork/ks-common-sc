// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IManagementSimple} from '../interfaces/IManagementSimple.sol';
import {KSRoles} from '../libraries/KSRoles.sol';
import {Common} from './Common.sol';

import {AccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {Pausable} from 'openzeppelin-contracts/contracts/utils/Pausable.sol';

/**
 * @title ManagementSimple
 * @notice Role management for contracts whose default admin is a single owner account
 * @dev {DEFAULT_ADMIN_ROLE} is held by {Ownable-owner} instead of being stored in
 * {AccessControl}, so it cannot be granted, revoked or renounced through the role functions
 * and no account holds it once ownership is renounced. It moves only with ownership, in one
 * step and with no delay; {ManagementBase} applies the two-step rules of
 * {AccessControlDefaultAdminRules} instead.
 */
abstract contract ManagementSimple is IManagementSimple, Common, AccessControl, Ownable, Pausable {
  /// @inheritdoc IManagementSimple
  mapping(bytes32 role => bytes32 roleRevoker) public roleRevokers;

  /**
   * @param initialDefaultAdmin The initial owner, and therefore the {DEFAULT_ADMIN_ROLE} holder
   * @param initialGuardians The accounts granted {KSRoles-GUARDIAN_ROLE}
   */
  constructor(address initialDefaultAdmin, address[] memory initialGuardians)
    Ownable(initialDefaultAdmin)
  {
    _batchGrantRole(KSRoles.GUARDIAN_ROLE, initialGuardians);
  }

  /// @notice Reverts unless the caller holds `role` or {DEFAULT_ADMIN_ROLE}
  modifier onlyRoleOrDefaultAdmin(bytes32 role) {
    if (!hasRole(role, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      bytes32[] memory neededRoles = new bytes32[](2);
      neededRoles[0] = role;
      neededRoles[1] = DEFAULT_ADMIN_ROLE;

      revert UnauthorizedAccount(_msgSender(), neededRoles);
    }
    _;
  }

  /// @inheritdoc IManagementSimple
  function setRoleRevoker(bytes32 role, bytes32 roleRevoker)
    external
    virtual
    onlyRole(getRoleAdmin(role))
  {
    _setRoleRevoker(role, roleRevoker);
  }

  /// @inheritdoc IManagementSimple
  function pause() external virtual onlyRoleOrDefaultAdmin(KSRoles.GUARDIAN_ROLE) {
    _pause();
  }

  /// @inheritdoc IManagementSimple
  function unpause() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /**
   * @inheritdoc IAccessControl
   * @dev {DEFAULT_ADMIN_ROLE} is held by {Ownable-owner} alone, and by no account once
   * ownership is renounced
   */
  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    if (role == DEFAULT_ADMIN_ROLE) {
      return account != address(0) && account == owner();
    }

    return super.hasRole(role, account);
  }

  /**
   * @inheritdoc IAccessControl
   * @dev Callable by the holders of either the revoker role set for `role` or its admin role.
   * Reverts for {DEFAULT_ADMIN_ROLE}.
   */
  function revokeRole(bytes32 role, address account) public virtual override {
    bytes32[] memory neededRoles = new bytes32[](2);
    neededRoles[0] = roleRevokers[role];
    neededRoles[1] = getRoleAdmin(role);

    if (!hasRole(neededRoles[0], _msgSender()) && !hasRole(neededRoles[1], _msgSender())) {
      revert UnauthorizedAccount(_msgSender(), neededRoles);
    }

    _revokeRole(role, account);
  }

  /// @dev Grants `role` to each of `accounts`, without access restriction
  function _batchGrantRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _grantRole(role, accounts[i]);
    }
  }

  /// @dev Revokes `role` from each of `accounts`, without access restriction
  function _batchRevokeRole(bytes32 role, address[] memory accounts) internal {
    for (uint256 i = 0; i < accounts.length; i++) {
      _revokeRole(role, accounts[i]);
    }
  }

  /// @dev Reverts for {DEFAULT_ADMIN_ROLE}, which follows {Ownable-owner}
  function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
    if (role == DEFAULT_ADMIN_ROLE) {
      revert DefaultAdminRoleActionNotAllowed();
    }

    return super._grantRole(role, account);
  }

  /// @dev Reverts for {DEFAULT_ADMIN_ROLE}, which follows {Ownable-owner}
  function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
    if (role == DEFAULT_ADMIN_ROLE) {
      revert DefaultAdminRoleActionNotAllowed();
    }

    return super._revokeRole(role, account);
  }

  /// @dev See {setRoleRevoker}, without access restriction
  function _setRoleRevoker(bytes32 role, bytes32 roleRevoker) internal virtual {
    if (role == DEFAULT_ADMIN_ROLE) {
      revert DefaultAdminRoleActionNotAllowed();
    }
    if (role == roleRevoker) {
      revert SelfRoleRevokerNotAllowed();
    }

    bytes32 previousRoleRevoker = roleRevokers[role];
    roleRevokers[role] = roleRevoker;
    emit RoleRevokerChanged(role, previousRoleRevoker, roleRevoker);
  }
}
