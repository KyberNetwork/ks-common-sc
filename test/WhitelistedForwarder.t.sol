// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'src/KSWhitelistedForwarder.sol';

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IWETH} from 'src/interfaces/IWETH.sol';

interface IStETH {
  function submit(address _referral) external payable;
}

contract WhitelistedForwarderTest is Test {
  KSWhitelistedForwarder public forwarder;

  bytes32 public constant WHITELISTED_ROLE = keccak256('WHITELISTED_ROLE');

  address admin = makeAddr('admin');

  address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

  address alice = makeAddr('alice');

  function setUp() public {
    vm.createSelectFork(vm.envString('RPC_1'), 22_930_000);

    forwarder = new KSWhitelistedForwarder(admin, new address[](0));
  }

  function test_forward() public {
    // Case 1: transfer from alice to address(this)
    deal(usdc, alice, 1e6);

    vm.prank(alice);
    IERC20(usdc).approve(address(forwarder), 1e6);

    bytes memory data = abi.encodeCall(IERC20.transferFrom, (alice, address(this), 1e6));

    _expectRevert(address(this));
    forwarder.forward(usdc, data);

    _whitelist(address(this));
    forwarder.forward(usdc, data);

    assertEq(IERC20(usdc).balanceOf(address(this)), 1e6);
    assertEq(IERC20(usdc).balanceOf(alice), 0);

    // Case 2: wrap ETH to WETH
    deal(address(forwarder), 0);

    data = abi.encodeCall(IWETH.deposit, ());
    forwarder.forward{value: 1e18}(weth, data);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), 1e18);
    assertEq(address(forwarder).balance, 0);
  }

  function test_forwardValue() public {
    // wrap ETH to WETH
    deal(address(forwarder), 0);

    bytes memory data = abi.encodeCall(IWETH.deposit, ());

    _expectRevert(address(this));
    forwarder.forwardValue{value: 1e18}(weth, data, 1e18);

    _whitelist(address(this));
    forwarder.forwardValue{value: 1e18}(weth, data, 1e18);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), 1e18);
  }

  function test_forwardBatch() public {
    // transfer from alice to address(this)
    deal(usdc, alice, 1e6);
    deal(weth, alice, 1e18);
    deal(weth, address(this), 0);

    vm.startPrank(alice);
    IERC20(usdc).approve(address(forwarder), 1e6);
    IERC20(weth).approve(address(forwarder), 1e18);
    vm.stopPrank();

    address[] memory targets = new address[](2);
    targets[0] = usdc;
    targets[1] = weth;
    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeCall(IERC20.transferFrom, (alice, address(this), 1e6));
    data[1] = abi.encodeCall(IERC20.transferFrom, (alice, address(this), 1e18));

    _expectRevert(address(this));
    forwarder.forwardBatch(targets, data);

    _whitelist(address(this));
    forwarder.forwardBatch(targets, data);

    assertEq(IERC20(usdc).balanceOf(address(this)), 1e6);
    assertEq(IERC20(weth).balanceOf(address(this)), 1e18);
    assertEq(IERC20(usdc).balanceOf(alice), 0);
    assertEq(IERC20(weth).balanceOf(alice), 0);
  }

  function test_forwardBatchValue() public {
    // wrap ETH to WETH and submit to steth
    deal(address(forwarder), 0);

    address[] memory targets = new address[](2);
    targets[0] = weth;
    targets[1] = steth;
    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeCall(IWETH.deposit, ());
    data[1] = abi.encodeCall(IStETH.submit, (address(this)));
    uint256[] memory values = new uint256[](2);
    values[0] = 1e18;
    values[1] = 1e18;

    _expectRevert(address(this));
    forwarder.forwardBatchValue{value: 2e18}(targets, data, values);

    _whitelist(address(this));
    forwarder.forwardBatchValue{value: 2e18}(targets, data, values);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), 1e18);
    assertApproxEqAbs(IERC20(steth).balanceOf(address(forwarder)), 1e18, 1);
    assertEq(address(forwarder).balance, 0);
  }

  function _whitelist(address account) internal {
    vm.startPrank(admin);
    forwarder.grantRole(WHITELISTED_ROLE, account);
    vm.stopPrank();
  }

  function _expectRevert(address account) internal {
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, account, WHITELISTED_ROLE
      )
    );
  }
}
