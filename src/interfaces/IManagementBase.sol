// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

interface IManagementBase {
  /// @notice Thrown when the account is missing one of the required roles
  error AccessControlUnauthorizedAccount(address account, bytes32[] neededRoles);

  event RoleRevokerChanged(
    bytes32 indexed role, bytes32 indexed previousRoleRevoker, bytes32 indexed newRoleRevoker
  );

  /// @notice Transfer {defaultAdmin} to a new account
  /// @dev Mimics the {Ownable-transferOwnership} function
  /// @param newOwner The new {defaultAdmin}
  function transferOwnership(address newOwner) external;

  /// @notice Batch grant roles to multiple accounts
  /// @param role The role to grant
  /// @param accounts The accounts to grant the role to
  function batchGrantRole(bytes32 role, address[] memory accounts) external;

  /// @notice Batch revoke roles from multiple accounts
  /// @param role The role to revoke
  /// @param accounts The accounts to revoke the role from
  function batchRevokeRole(bytes32 role, address[] memory accounts) external;

  /// @notice Returns the role other than the admin role that can revoke the given role
  function roleRevokers(bytes32 role) external view returns (bytes32);

  /// @notice Sets the revoker roles for multiple roles
  /// @param role The role to update the revoker role for
  /// @param roleRevoker The new revoker role for the role
  function setRoleRevoker(bytes32 role, bytes32 roleRevoker) external;
}
