// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Config.sol';
import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';

import {ICREATE3Factory} from 'src/interfaces/ICREATE3Factory.sol';

contract BaseScript is Script, Config {
  using stdJson for string;

  event ReadAddress(string key, address result);
  event ReadBool(string key, bool result);
  event ReadAddressArray(string key, address[] result);
  event ReadBytes(string key, bytes result);
  event ReadBytesArray(string key, bytes[] result);

  event DeployContract(string key, address result);

  address internal constant DEFAULT_CREATE3_DEPLOYER = 0xc7c662Fc760FE1d5cB97fd8A68cb43A046da3F7d;

  string path;

  modifier multiChain(string[] memory chainIdsOrAliases) {
    _loadConfigs(chainIdsOrAliases);
    for (uint256 i = 0; i < chainIdsOrAliases.length; i++) {
      string memory chainIdOrAlias = chainIdsOrAliases[i];
      vm.createSelectFork(_getRpcUrl(chainIdOrAlias));
      _loadConfig(chainIdOrAlias);
      vm.startBroadcast();
      _;
      vm.stopBroadcast();
    }
  }

  function setUp() public virtual {
    path = string.concat(vm.projectRoot(), '/script/config/');
    _loadConfigs();
  }

  function _loadConfigs() internal virtual {}

  function _loadConfigs(string[] memory chainIdsOrAliases) internal virtual {}

  function _loadConfig(string memory chainIdOrAlias) internal virtual {}

  function _create3Deployer() internal returns (address) {
    return _readAddressOr('create3-deployer', DEFAULT_CREATE3_DEPLOYER);
  }

  function _getJsonString(string memory key) internal view returns (string memory) {
    try vm.readFile(string.concat(path, key, '.json')) returns (string memory json) {
      return json;
    } catch {
      return '{}';
    }
  }

  function _readAddress(string memory key) internal returns (address result) {
    return _readAddressByChainId(key, vm.getChainId());
  }

  function _readAddressByChainId(string memory key, uint256 chainId)
    internal
    returns (address result)
  {
    string memory json = _getJsonString(key);
    if (json.keyExists(_toDotChainId(chainId))) {
      result = json.readAddress(_toDotChainId(chainId));
    } else {
      result = json.readAddress('.0');
    }

    emit ReadAddress(key, result);
  }

  function _readAddressOr(string memory key, address defaultValue)
    internal
    returns (address result)
  {
    string memory json = _getJsonString(key);
    result = json.readAddressOr(_dotChainId(), defaultValue);

    emit ReadAddress(key, result);
  }

  function _writeAddress(string memory key, address value) internal {
    if (!vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
      return;
    }
    vm.serializeJson(key, _getJsonString(key));
    vm.writeJson(key.serialize(_chainId(), value), string.concat(path, key, '.json'));
  }

  function _readBool(string memory key) internal returns (bool result) {
    return _readBoolByChainId(key, vm.getChainId());
  }

  function _readBoolByChainId(string memory key, uint256 chainId) internal returns (bool result) {
    string memory json = _getJsonString(key);
    if (json.keyExists(_toDotChainId(chainId))) {
      result = json.readBool(_toDotChainId(chainId));
    } else {
      result = json.readBool('.0');
    }

    emit ReadBool(key, result);
  }

  function _readBoolOr(string memory key, bool defaultValue) internal returns (bool result) {
    string memory json = _getJsonString(key);
    result = json.readBoolOr(_dotChainId(), defaultValue);

    emit ReadBool(key, result);
  }

  function _readAddressArray(string memory key) internal returns (address[] memory result) {
    return _readAddressArrayByChainId(key, vm.getChainId());
  }

  function _readAddressArrayByChainId(string memory key, uint256 chainId)
    internal
    returns (address[] memory result)
  {
    string memory json = _getJsonString(key);
    if (json.keyExists(_toDotChainId(chainId))) {
      result = json.readAddressArray(_toDotChainId(chainId));
    } else {
      result = json.readAddressArray('.0');
    }

    emit ReadAddressArray(key, result);
  }

  function _readAddressArrayOr(string memory key, address[] memory defaultValue)
    internal
    returns (address[] memory result)
  {
    string memory json = _getJsonString(key);
    result = json.readAddressArrayOr(_dotChainId(), defaultValue);

    emit ReadAddressArray(key, result);
  }

  function _readBytes(string memory key) internal returns (bytes memory result) {
    return _readBytesByChainId(key, vm.getChainId());
  }

  function _readBytesByChainId(string memory key, uint256 chainId)
    internal
    returns (bytes memory result)
  {
    string memory json = _getJsonString(key);
    if (json.keyExists(_toDotChainId(chainId))) {
      result = json.readBytes(_toDotChainId(chainId));
    } else {
      result = json.readBytes('.0');
    }
    emit ReadBytes(key, result);
  }

  function _readBytesOr(string memory key, bytes memory defaultValue)
    internal
    returns (bytes memory result)
  {
    string memory json = _getJsonString(key);
    result = json.readBytesOr(_dotChainId(), defaultValue);

    emit ReadBytes(key, result);
  }

  function _readBytesArray(string memory key) internal returns (bytes[] memory result) {
    return _readBytesArrayByChainId(key, vm.getChainId());
  }

  function _readBytesArrayByChainId(string memory key, uint256 chainId)
    internal
    returns (bytes[] memory result)
  {
    string memory json = _getJsonString(key);
    if (json.keyExists(_toDotChainId(chainId))) {
      result = json.readBytesArray(_toDotChainId(chainId));
    } else {
      result = json.readBytesArray('.0');
    }
    emit ReadBytesArray(key, result);
  }

  function _readBytesArrayOr(string memory key, bytes[] memory defaultValue)
    internal
    returns (bytes[] memory result)
  {
    string memory json = _getJsonString(key);
    result = json.readBytesArrayOr(_dotChainId(), defaultValue);

    emit ReadBytesArray(key, result);
  }

  /**
   * @notice Deploy a contract using CREATE3
   * @param salt the salt to deploy the contract with
   * @param creationCode the creation code of the contract
   */
  function _create3Deploy(bytes32 salt, bytes memory creationCode)
    internal
    returns (address deployed, bool success)
  {
    address create3Deployer = _create3Deployer();
    deployed = ICREATE3Factory(create3Deployer).getDeployed(msg.sender, salt);

    if (deployed.code.length == 0) {
      success = true;
      ICREATE3Factory(create3Deployer).deploy(salt, creationCode);
    }
  }

  function _toDotChainId(uint256 chainId) internal view returns (string memory) {
    return string.concat('.', vm.toString(chainId));
  }

  function _dotChainId() internal returns (string memory) {
    return string.concat('.', _chainId());
  }

  function _chainId() internal returns (string memory) {
    return vm.toString(vm.getChainId());
  }

  function _getRpcUrl(string memory chainIdOrAlias) internal returns (string memory) {
    return vm.envOr(string.concat('RPC_', chainIdOrAlias), chainIdOrAlias);
  }
}
