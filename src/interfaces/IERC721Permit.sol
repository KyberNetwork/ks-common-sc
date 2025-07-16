// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///
/// @dev Interface for token permits for ERC-721
///
interface IERC721Permit {
  /// ERC165 bytes to add to interface array - set in parent contract
  ///
  /// _INTERFACE_ID_ERC4494 = 0x5604e225

  /// @notice Function to approve by way of owner signature
  /// @param spender the address to approve
  /// @param tokenId the index of the NFT to approve the spender on
  /// @param deadline a timestamp expiry for the permit
  /// @param sig a traditional or EIP-2098 signature
  function permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) external;
}
