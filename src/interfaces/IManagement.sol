// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from 'openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from 'openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

interface IManagement {
  /// @notice Emitted when some of ERC20 tokens are rescued
  event RescueERC20s(address[] tokens, uint256[] amounts, address recipient);

  /// @notice Emitted when some of ERC721 tokens are rescued
  event RescueERC721s(IERC721[] tokens, uint256[] tokenIds, address recipient);

  /// @notice Emitted when some of ERC1155 tokens are rescued
  event RescueERC1155s(IERC1155[] tokens, uint256[] tokenIds, uint256[] amounts, address recipient);

  /// @notice Batch grant roles to multiple accounts
  /// @param role The role to grant
  /// @param accounts The accounts to grant the role to
  function batchGrantRole(bytes32 role, address[] memory accounts) external;

  /// @notice Batch revoke roles from multiple accounts
  /// @param role The role to revoke
  /// @param accounts The accounts to revoke the role from
  function batchRevokeRole(bytes32 role, address[] memory accounts) external;

  /// @notice Pause the contract
  function pause() external;

  /// @notice Unpause the contract
  function unpause() external;

  /**
   * @notice Rescue some of ERC20 tokens stuck in the contract
   * @notice Can only be called by the current owner
   * @param tokens the addresses of the tokens to rescue
   * @param amounts the amounts of the tokens to rescue, set to 0 to rescue all
   * @param recipient the address to send the tokens to
   */
  function rescueERC20s(address[] calldata tokens, uint256[] memory amounts, address recipient)
    external;

  /**
   * @notice Rescue some of ERC721 tokens stuck in the contract
   * @notice Can only be called by the current owner
   * @param tokens the addresses of the tokens to rescue
   * @param tokenIds the IDs of the tokens to rescue
   * @param recipient the address to send the tokens to
   */
  function rescueERC721s(IERC721[] calldata tokens, uint256[] calldata tokenIds, address recipient)
    external;

  /**
   * @notice Rescue some of ERC1155 tokens stuck in the contract
   * @notice Can only be called by the current owner
   * @param tokens the addresses of the tokens to rescue
   * @param tokenIds the IDs of the tokens to rescue
   * @param amounts the amounts of the tokens to rescue, set to 0 to rescue all
   * @param recipient the address to send the tokens to
   */
  function rescueERC1155s(
    IERC1155[] calldata tokens,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address recipient
  ) external;
}
