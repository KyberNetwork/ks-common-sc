// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'script/Base.s.sol';

import {ManagementBase} from 'src/base/ManagementBase.sol';

contract UpdateRolesScript is BaseScript {
  // forge script UpdateRolesScript --sig "run(address,string,address[],bool)"
  // "0xdfc2c23366897a83b5982E67Adda04EB9f481Ad1" "0x8429d542926e6695b59ac6fbdcd9b37e8b1aeb757afab06ab60b1bb5878c3b49"
  // "[0x46323B0562975BC66bc6AC99950269024F05eC47]" "true"
  function run(
    ManagementBase management,
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
