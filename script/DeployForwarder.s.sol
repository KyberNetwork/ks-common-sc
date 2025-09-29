// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './Base.s.sol';
import 'src/KSGenericForwarder.sol';

contract DeployForwarderScript is BaseScript {
  string salt = '250813';

  function run() public {
    if (bytes(salt).length == 0) {
      revert('salt is required');
    }
    salt = string.concat('KSGenericForwarder_', salt);

    vm.startBroadcast();
    address forwarder =
      _create3Deploy(keccak256(abi.encodePacked(salt)), type(KSGenericForwarder).creationCode);
    vm.stopBroadcast();

    _writeAddress('forwarder', forwarder);

    emit DeployContract('KSGenericForwarder', forwarder);
  }
}
