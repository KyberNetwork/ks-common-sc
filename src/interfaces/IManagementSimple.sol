// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IManagementSimple
/// @notice Interface of {ManagementSimple}
interface IManagementSimple {
  /// @notice Thrown when the account is missing one of the required roles
  error UnauthorizedAccount(address account, bytes32[] neededRoles);

  /// @notice Thrown when a role action targets the default admin role
  error DefaultAdminRoleActionNotAllowed();

  /// @notice Thrown when setting a role as its own revoker role
  error SelfRoleRevokerNotAllowed();

  /// @notice Emitted when the role revoker for a role is changed
  event RoleRevokerChanged(
    bytes32 indexed role, bytes32 indexed previousRoleRevoker, bytes32 indexed newRoleRevoker
  );

  /**
   * @notice Returns the role other than the admin role that can revoke the given role
   * @dev Unset for every role by default, which reads as the default admin role
   * @param role The role to read the revoker role of
   * @return The revoker role for the role
   */
  function roleRevokers(bytes32 role) external view returns (bytes32);

  /**
   * @notice Sets the role revoker for a given role
   * @dev Callable by the holders of the admin role of the role. The default admin role cannot
   * be given a revoker role, and a role cannot be its own revoker.
   * @param role The role to update the revoker role for
   * @param roleRevoker The new revoker role for the role
   */
  function setRoleRevoker(bytes32 role, bytes32 roleRevoker) external;

  /// @notice Pause the contract, callable by a guardian or the default admin
  function pause() external;

  /// @notice Unpause the contract, callable by the default admin
  function unpause() external;
}
