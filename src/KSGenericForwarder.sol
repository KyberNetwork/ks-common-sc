// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Common} from './base/Common.sol';
import {IKSGenericForwarder} from './interfaces/IKSGenericForwarder.sol';

import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';

contract KSGenericForwarder is Common, IKSGenericForwarder {
  using Address for address;

  receive() external payable {}

  function forward(address target, bytes calldata data)
    external
    payable
    override
    returns (bytes memory)
  {
    return target.functionCallWithValue(data, msg.value);
  }

  function forwardValue(address target, bytes calldata data, uint256 value)
    external
    payable
    override
    returns (bytes memory)
  {
    return target.functionCallWithValue(data, value);
  }

  function forwardBatch(address[] calldata targets, bytes[] calldata data)
    external
    override
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
    external
    payable
    override
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
