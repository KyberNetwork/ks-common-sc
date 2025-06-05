// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/// @notice Interface for DAI-style permits
interface IDaiLikePermit {
  /// @notice Permit a spender to a given amount of the holder's token via the holder's EIP-712 signature
  /// @dev May fail if the holder's nonce was invalidated in-flight by invalidateNonce
  /// @param holder The holder of the tokens being approved
  /// @param spender The address permissioned on the allowed tokens
  /// @param nonce The nonce of the holder
  /// @param expiry The expiry of the permit
  /// @param allowed Whether the permit is allowed
  /// @param v The v component of the signature
  /// @param r The r component of the signature
  /// @param s The s component of the signature
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
