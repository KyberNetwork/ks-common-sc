// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'script/Base.s.sol';

import {Management} from 'src/base/Management.sol';

contract UpdateRolesScript is BaseScript {
  function run(
    Management management,
    string calldata roleName,
    address[] calldata accounts,
    bool isGrant
  ) public {
    bytes32 role = keccak256(abi.encodePacked(roleName));
    vm.startBroadcast();
    if (isGrant) {
      management.batchGrantRole(role, accounts);
    } else {
      management.batchRevokeRole(role, accounts);
    }
    vm.stopBroadcast();
  }
}
