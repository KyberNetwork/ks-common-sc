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

  function test_forward(uint256 usdcAmount, uint256 wethAmount) public {
    usdcAmount = bound(usdcAmount, 1, 1e8);
    wethAmount = bound(wethAmount, 1, 1e18);

    // Case 1: transfer from alice to address(this)
    deal(usdc, alice, usdcAmount);

    vm.prank(alice);
    IERC20(usdc).approve(address(forwarder), usdcAmount);

    bytes memory data = abi.encodeCall(IERC20.transferFrom, (alice, address(this), usdcAmount));

    _expectRevert(address(this));
    forwarder.forward(usdc, data);

    _whitelist(address(this));
    forwarder.forward(usdc, data);

    assertEq(IERC20(usdc).balanceOf(address(this)), usdcAmount);
    assertEq(IERC20(usdc).balanceOf(alice), 0);

    // Case 2: wrap ETH to WETH
    deal(address(forwarder), 0);

    data = abi.encodeCall(IWETH.deposit, ());
    forwarder.forward{value: wethAmount}(weth, data);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), wethAmount);
    assertEq(address(forwarder).balance, 0);
  }

  function test_forwardValue(uint256 wethAmount, uint256 msgValue) public {
    wethAmount = bound(wethAmount, 1, 1e18);
    msgValue = bound(msgValue, wethAmount, 1e18);

    // wrap ETH to WETH
    deal(address(forwarder), 0);

    bytes memory data = abi.encodeCall(IWETH.deposit, ());

    _expectRevert(address(this));
    forwarder.forwardValue{value: msgValue}(weth, data, wethAmount);

    _whitelist(address(this));
    forwarder.forwardValue{value: msgValue}(weth, data, wethAmount);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), wethAmount);
    assertEq(address(forwarder).balance, msgValue - wethAmount);
  }

  function test_forwardBatch(uint256 usdcAmount, uint256 wethAmount) public {
    usdcAmount = bound(usdcAmount, 1, 1e8);
    wethAmount = bound(wethAmount, 1, 1e18);

    // transfer from alice to address(this)
    deal(usdc, alice, usdcAmount);
    deal(weth, alice, wethAmount);
    deal(weth, address(this), 0);

    vm.startPrank(alice);
    IERC20(usdc).approve(address(forwarder), usdcAmount);
    IERC20(weth).approve(address(forwarder), wethAmount);
    vm.stopPrank();

    address[] memory targets = new address[](2);
    targets[0] = usdc;
    targets[1] = weth;
    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeCall(IERC20.transferFrom, (alice, address(this), usdcAmount));
    data[1] = abi.encodeCall(IERC20.transferFrom, (alice, address(this), wethAmount));

    _expectRevert(address(this));
    forwarder.forwardBatch(targets, data);

    _whitelist(address(this));
    forwarder.forwardBatch(targets, data);

    assertEq(IERC20(usdc).balanceOf(address(this)), usdcAmount);
    assertEq(IERC20(weth).balanceOf(address(this)), wethAmount);
    assertEq(IERC20(usdc).balanceOf(alice), 0);
    assertEq(IERC20(weth).balanceOf(alice), 0);
  }

  function test_forwardBatchValue(uint256 wethAmount, uint256 stethAmount, uint256 msgValue)
    public
  {
    wethAmount = bound(wethAmount, 1, 1e18);
    stethAmount = bound(stethAmount, 1, 1e18);
    msgValue = bound(msgValue, wethAmount + stethAmount, 2e18);

    // wrap ETH to WETH and submit to steth
    deal(address(forwarder), 0);

    address[] memory targets = new address[](2);
    targets[0] = weth;
    targets[1] = steth;
    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeCall(IWETH.deposit, ());
    data[1] = abi.encodeCall(IStETH.submit, (address(this)));
    uint256[] memory values = new uint256[](2);
    values[0] = wethAmount;
    values[1] = stethAmount;

    _expectRevert(address(this));
    forwarder.forwardBatchValue{value: msgValue}(targets, data, values);

    _whitelist(address(this));
    forwarder.forwardBatchValue{value: msgValue}(targets, data, values);

    assertEq(IERC20(weth).balanceOf(address(forwarder)), wethAmount);
    assertApproxEqAbs(IERC20(steth).balanceOf(address(forwarder)), stethAmount, 10);
    assertEq(address(forwarder).balance, msgValue - wethAmount - stethAmount);
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
