// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './Base.s.sol';
import 'src/KSGenericForwarder.sol';

contract DeployForwarderScript is BaseScript {
  string salt = '260123';

  function run() public {
    if (bytes(salt).length == 0) {
      revert('salt is required');
    }
    string memory contractSalt = string.concat('KSGenericForwarder_', salt);

    vm.startBroadcast();
    (address forwarder,) = _create3Deploy(
      keccak256(abi.encodePacked(contractSalt)), type(KSGenericForwarder).creationCode
    );
    vm.stopBroadcast();

    if (vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
      _writeAddress('forwarder', forwarder);
    }
    emit DeployContract('KSGenericForwarder', forwarder);
  }
}
