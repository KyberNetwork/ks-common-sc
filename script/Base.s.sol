// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';

import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/contracts/utils/Address.sol';

contract BaseScript is Script {
  using stdJson for string;
  using Address for address;

  event ReadAddress(string key, address result);
  event ReadBool(string key, bool result);
  event ReadAddressArray(string key, address[] result);

  event DeployContract(string key, address result);

  address constant DEFAULT_CREATE3_DEPLOYER = 0xc7c662Fc760FE1d5cB97fd8A68cb43A046da3F7d;

  string path;
  string chainId;

  address create3Deployer;

  function setUp() public virtual {
    path = string.concat(vm.projectRoot(), '/script/config/');
    chainId = vm.toString(block.chainid);

    create3Deployer = _readAddressOr('create3-deployer', DEFAULT_CREATE3_DEPLOYER);
  }

  function _getJsonString(string memory key) internal view returns (string memory) {
    try vm.readFile(string.concat(path, key, '.json')) returns (string memory json) {
      return json;
    } catch {
      return '{}';
    }
  }

  function _readAddress(string memory key) internal returns (address result) {
    string memory json = _getJsonString(key);
    result = json.readAddress(string.concat('.', chainId));

    emit ReadAddress(key, result);
  }

  function _readAddressOr(string memory key, address defaultValue)
    internal
    returns (address result)
  {
    string memory json = _getJsonString(key);
    result = json.readAddressOr(string.concat('.', chainId), defaultValue);

    emit ReadAddress(key, result);
  }

  function _writeAddress(string memory key, address value) internal {
    if (!vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
      return;
    }
    vm.serializeJson(key, _getJsonString(key));
    vm.writeJson(key.serialize(chainId, value), string.concat(path, key, '.json'));
  }

  function _readBool(string memory key) internal returns (bool result) {
    string memory json = _getJsonString(key);
    result = json.readBool(string.concat('.', chainId));

    emit ReadBool(key, result);
  }

  function _readAddressArray(string memory key) internal returns (address[] memory result) {
    string memory json = _getJsonString(key);
    result = json.readAddressArray(string.concat('.', chainId));

    emit ReadAddressArray(key, result);
  }

  /**
   * @notice Deploy a contract using CREATE3
   * @param salt the salt to deploy the contract with
   * @param creationCode the creation code of the contract
   */
  function _create3Deploy(bytes32 salt, bytes memory creationCode)
    internal
    returns (address deployed)
  {
    bytes memory result = create3Deployer.functionCall(
      abi.encodeWithSignature('deploy(bytes32,bytes)', salt, creationCode)
    );
    deployed = abi.decode(result, (address));
  }
}
