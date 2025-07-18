// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICommon} from '../interfaces/ICommon.sol';

contract Common is ICommon {
  modifier checkAddress(address addr) {
    require(addr != address(0), InvalidAddress());
    _;
  }

  modifier checkLengths(uint256 length1, uint256 length2) {
    require(length1 == length2, MismatchedArrayLengths());
    _;
  }
}
