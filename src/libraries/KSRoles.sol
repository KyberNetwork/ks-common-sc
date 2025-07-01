// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Library for managing roles for KyberSwap
library KSRoles {
  /// @notice Role for the operators
  bytes32 internal constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

  /// @notice Role for the guardians
  bytes32 internal constant GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');

  /// @notice Role for the rescuers
  bytes32 internal constant RESCUER_ROLE = keccak256('RESCUER_ROLE');
}
