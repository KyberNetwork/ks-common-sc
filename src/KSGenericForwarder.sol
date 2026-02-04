// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Common} from './base/Common.sol';
import {IKSGenericForwarder} from './interfaces/IKSGenericForwarder.sol';

import {
  ERC1155Holder
} from 'openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import {ERC721Holder} from 'openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol';
import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';

contract KSGenericForwarder is IKSGenericForwarder, ERC721Holder, ERC1155Holder, Common {
  using Address for address;

  receive() external payable {}

  function forward(address target, bytes calldata data)
    public
    payable
    virtual
    returns (bytes memory)
  {
    return target.functionCallWithValue(data, msg.value);
  }

  function forwardValue(address target, bytes calldata data, uint256 value)
    public
    payable
    virtual
    returns (bytes memory)
  {
    return target.functionCallWithValue(data, value);
  }

  function forwardBatch(address[] calldata targets, bytes[] calldata data)
    public
    virtual
    checkLengths(targets.length, data.length)
    returns (bytes[] memory results)
  {
    results = new bytes[](targets.length);

    for (uint256 i = 0; i < targets.length; i++) {
      results[i] = targets[i].functionCall(data[i]);
    }
  }

  function forwardBatchValue(
    address[] calldata targets,
    bytes[] calldata data,
    uint256[] calldata values
  )
    public
    payable
    virtual
    checkLengths(targets.length, data.length)
    checkLengths(targets.length, values.length)
    returns (bytes[] memory results)
  {
    results = new bytes[](targets.length);

    for (uint256 i = 0; i < targets.length; i++) {
      results[i] = targets[i].functionCallWithValue(data[i], values[i]);
    }
  }
}
