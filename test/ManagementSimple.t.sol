// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'src/base/ManagementSimple.sol';

import 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

contract SimpleManagement is ManagementSimple {
  constructor(address initialDefaultAdmin, address[] memory initialGuardians)
    ManagementSimple(initialDefaultAdmin, initialGuardians)
  {}
}

contract ManagementSimpleTest is Test {
  SimpleManagement public management;

  bytes32 public defaultAdminRole;

  address admin = makeAddr('admin');
  address guardian = makeAddr('guardian');
  address alice = makeAddr('alice');

  function setUp() public {
    address[] memory initialGuardians = new address[](1);
    initialGuardians[0] = guardian;

    management = new SimpleManagement(admin, initialGuardians);
    defaultAdminRole = management.DEFAULT_ADMIN_ROLE();
  }

  function test_constructor() public view {
    assertEq(management.owner(), admin);
    assertTrue(management.hasRole(defaultAdminRole, admin));
    assertTrue(management.hasRole(KSRoles.GUARDIAN_ROLE, guardian));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_transferOwnership(address newOwner) public {
    vm.assume(newOwner != address(0));
    vm.assume(newOwner != admin);

    vm.prank(admin);
    management.transferOwnership(newOwner);

    assertEq(management.owner(), newOwner);
    assertTrue(management.hasRole(defaultAdminRole, newOwner));
    assertFalse(management.hasRole(defaultAdminRole, admin));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_grantDefaultAdminRole_reverts(address account) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.grantRole(defaultAdminRole, account);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeDefaultAdminRole_reverts(address account) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.revokeRole(defaultAdminRole, account);
  }

  function test_renounceDefaultAdminRole_reverts() public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.renounceRole(defaultAdminRole, admin);
  }

  function test_renounceOwnership() public {
    vm.prank(admin);
    management.renounceOwnership();

    assertEq(management.owner(), address(0));
    assertFalse(management.hasRole(defaultAdminRole, admin));
    assertFalse(management.hasRole(defaultAdminRole, address(0)));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_grantRole(bytes32 role) public {
    vm.assume(role != defaultAdminRole);

    vm.prank(admin);
    management.grantRole(role, alice);

    assertTrue(management.hasRole(role, alice));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_roleRevokers(bytes32 role, bytes32 roleRevoker) public {
    vm.assume(role != 0);
    vm.assume(roleRevoker != 0);
    vm.assume(roleRevoker != role);

    address account1 = makeAddr('account1');
    address account2 = makeAddr('account2');

    vm.startPrank(admin);
    management.grantRole(role, account1);
    management.grantRole(roleRevoker, account2);
    management.setRoleRevoker(role, roleRevoker);
    vm.stopPrank();

    assertEq(management.roleRevokers(role), roleRevoker);

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleRevoked(role, account1, account2);

    vm.prank(account2);
    management.revokeRole(role, account1);
    assertFalse(management.hasRole(role, account1));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker_revertsOnSameRole(bytes32 role) public {
    vm.assume(role != defaultAdminRole);

    vm.expectRevert(IManagementSimple.SelfRoleRevokerNotAllowed.selector);

    vm.prank(admin);
    management.setRoleRevoker(role, role);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker_revertsOnDefaultAdminRole(bytes32 roleRevoker) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.setRoleRevoker(defaultAdminRole, roleRevoker);
  }

  function test_pause_byGuardian() public {
    vm.prank(guardian);
    management.pause();

    assertTrue(management.paused());
  }

  function test_pause_byDefaultAdmin() public {
    vm.prank(admin);
    management.pause();

    assertTrue(management.paused());
  }

  function test_pause_revertsOnUnauthorizedAccount() public {
    bytes32[] memory neededRoles = new bytes32[](2);
    neededRoles[0] = KSRoles.GUARDIAN_ROLE;
    neededRoles[1] = defaultAdminRole;

    vm.expectRevert(
      abi.encodeWithSelector(IManagementSimple.UnauthorizedAccount.selector, alice, neededRoles)
    );

    vm.prank(alice);
    management.pause();
  }

  function test_unpause() public {
    vm.prank(guardian);
    management.pause();

    vm.prank(admin);
    management.unpause();

    assertFalse(management.paused());
  }

  function test_unpause_revertsOnGuardian() public {
    vm.prank(guardian);
    management.pause();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, guardian, defaultAdminRole
      )
    );

    vm.prank(guardian);
    management.unpause();
  }
}
