// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../src/KSWhitelistedForwarder.sol';
import '../Base.s.sol';

contract DeployWhitelistedForwarderScript is BaseScript {
  string salt = '12312';

  function run(string[] memory chainIds) public multiChain(chainIds) {
    if (bytes(salt).length == 0) {
      revert('salt is required');
    }
    salt = string.concat('KSWhitelistedForwarder_', salt);

    address admin = _readAddress('smart-intent/forwarder-admin');
    address[] memory rescuers = _readAddressArray('smart-intent/forwarder-rescuers');

    bytes memory creationCode =
      abi.encodePacked(type(KSWhitelistedForwarder).creationCode, abi.encode(admin, rescuers));
    (address forwarder,) = _create3Deploy(keccak256(bytes(salt)), creationCode);

    _writeAddress('whitelisted-forwarder', address(forwarder));
    emit DeployContract('KSWhitelistedForwarder', address(forwarder));
  }
}
