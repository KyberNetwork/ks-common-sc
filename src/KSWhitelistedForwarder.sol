// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {KSGenericForwarder} from './KSGenericForwarder.sol';

import {ManagementBase} from './base/ManagementBase.sol';
import {ManagementRescuable} from './base/ManagementRescuable.sol';

import {
  AccessControlDefaultAdminRules
} from 'openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol';
import {
  ERC1155Holder
} from 'openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol';

contract KSWhitelistedForwarder is ManagementRescuable, KSGenericForwarder {
  bytes32 internal constant WHITELISTED_ROLE = keccak256('WHITELISTED_ROLE');

  constructor(address initialAdmin, address[] memory initialRescuers)
    ManagementBase(0, initialAdmin)
    ManagementRescuable(initialRescuers)
  {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlDefaultAdminRules, ERC1155Holder)
    returns (bool)
  {
    return AccessControlDefaultAdminRules.supportsInterface(interfaceId)
      || ERC1155Holder.supportsInterface(interfaceId);
  }

  function forward(address target, bytes calldata data)
    public
    payable
    override
    onlyRole(WHITELISTED_ROLE)
    returns (bytes memory)
  {
    return super.forward(target, data);
  }

  function forwardValue(address target, bytes calldata data, uint256 value)
    public
    payable
    override
    onlyRole(WHITELISTED_ROLE)
    returns (bytes memory)
  {
    return super.forwardValue(target, data, value);
  }

  function forwardBatch(address[] calldata targets, bytes[] calldata data)
    public
    override
    onlyRole(WHITELISTED_ROLE)
    returns (bytes[] memory)
  {
    return super.forwardBatch(targets, data);
  }

  function forwardBatchValue(
    address[] calldata targets,
    bytes[] calldata data,
    uint256[] calldata values
  ) public payable override onlyRole(WHITELISTED_ROLE) returns (bytes[] memory) {
    return super.forwardBatchValue(targets, data, values);
  }
}
