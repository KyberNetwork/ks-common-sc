// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'src/base/ManagementPausable.sol';
import 'src/base/ManagementRescuable.sol';
import 'src/libraries/token/TokenHelper.sol';

import 'openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol';
import 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract ERC721Mock is ERC721 {
  constructor() ERC721('ERC721Mock', 'E721M') {}

  function mint(address to, uint256 tokenId) public {
    _mint(to, tokenId);
  }
}

contract Management is ManagementRescuable, ManagementPausable {
  constructor(uint48 initialDelay, address initialAdmin) ManagementBase(initialDelay, initialAdmin) {}
}

contract ManagementTest is Test {
  Management public management;

  using TokenHelper for address;

  address admin = makeAddr('admin');

  function setUp() public {
    management = new Management(1 days, admin);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_transferOwnership(address newOwner) public {
    vm.assume(newOwner != address(0));

    vm.prank(admin);
    management.transferOwnership(newOwner);

    assertEq(management.defaultAdmin(), newOwner);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_rescueERC20s(
    uint256[5] memory mintAmounts,
    uint256[5] memory rescueAmounts,
    address recipient
  ) public {
    vm.assume(recipient != address(0));
    vm.assume(recipient != address(management));

    address[] memory tokens = new address[](5);
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Mock token = new ERC20Mock();
      token.mint(address(management), mintAmounts[i]);
      tokens[i] = address(token);

      rescueAmounts[i] = rescueAmounts[i] % 2 == 0 ? 0 : bound(rescueAmounts[i], 0, mintAmounts[i]);
    }

    vm.prank(admin);
    management.rescueERC20s(tokens, toDynamicArray(rescueAmounts), recipient);

    for (uint256 i = 0; i < tokens.length; i++) {
      assertEq(
        tokens[i].balanceOf(recipient), rescueAmounts[i] == 0 ? mintAmounts[i] : rescueAmounts[i]
      );
    }
  }

  /// forge-config: default.fuzz.runs = 20
  function test_rescueNative(uint256 dealAmount, uint256 rescueAmount, address recipient) public {
    vm.assume(recipient != address(0));
    vm.assume(recipient != address(management));
    vm.assume(recipient != address(this));
    vm.assume(recipient != address(vm));

    address[] memory tokens = new address[](1);
    tokens[0] = TokenHelper.NATIVE_ADDRESS;

    vm.deal(address(management), dealAmount);
    rescueAmount = rescueAmount % 2 == 0 ? 0 : bound(rescueAmount, 0, dealAmount);

    vm.prank(admin);
    management.rescueERC20s(tokens, toDynamicArray(rescueAmount), recipient);

    assertEq(recipient.balance, rescueAmount == 0 ? dealAmount : rescueAmount);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_rescueERC721s(uint256[5] memory tokenIds, address recipient) public {
    vm.assume(recipient != address(0));
    vm.assume(recipient != address(management));

    IERC721[] memory tokens = new IERC721[](5);
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC721Mock token = new ERC721Mock();
      token.mint(address(management), tokenIds[i]);
      tokens[i] = token;
    }

    vm.prank(admin);
    management.rescueERC721s(tokens, toDynamicArray(tokenIds), recipient);

    for (uint256 i = 0; i < tokens.length; i++) {
      assertEq(tokens[i].ownerOf(tokenIds[i]), recipient);
    }
  }

  function toDynamicArray(uint256 value) internal pure returns (uint256[] memory) {
    uint256[] memory dynamicArr = new uint256[](1);
    dynamicArr[0] = value;
    return dynamicArr;
  }

  function toDynamicArray(uint256[5] memory arr) internal pure returns (uint256[] memory) {
    uint256[] memory dynamicArr = new uint256[](5);
    for (uint256 i = 0; i < 5; i++) {
      dynamicArr[i] = arr[i];
    }
    return dynamicArr;
  }
}
