// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagementPausable {
  /// @notice Pause the contract
  function pause() external;

  /// @notice Unpause the contract
  function unpause() external;
}
