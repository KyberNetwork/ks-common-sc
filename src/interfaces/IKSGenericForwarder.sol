// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSGenericForwarder {
  function forward(address target, bytes calldata data) external payable returns (bytes memory);

  function forwardValue(address target, bytes calldata data, uint256 value)
    external
    payable
    returns (bytes memory);

  function forwardBatch(address[] calldata targets, bytes[] calldata data)
    external
    returns (bytes[] memory);

  function forwardBatchValue(
    address[] calldata targets,
    bytes[] calldata data,
    uint256[] calldata value
  ) external payable returns (bytes[] memory);
}
