// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import 'src/base/ManagementSimple.sol';

import 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import 'openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/// @dev Concrete {ManagementSimple} exposing the internal batch helpers that derived contracts use
contract SimpleManagement is ManagementSimple {
  constructor(address initialDefaultAdmin, address[] memory initialGuardians)
    ManagementSimple(initialDefaultAdmin, initialGuardians)
  {}

  function batchGrantRole(bytes32 role, address[] memory accounts) external {
    _batchGrantRole(role, accounts);
  }

  function batchRevokeRole(bytes32 role, address[] memory accounts) external {
    _batchRevokeRole(role, accounts);
  }
}

abstract contract ManagementSimpleBase is Test {
  struct Deployment {
    address initialDefaultAdmin;
    address initialGuardian;
  }

  struct RoleGrant {
    bytes32 role;
    address account;
  }

  struct BatchGrant {
    bytes32 role;
    address account0;
    address account1;
    address account2;
  }

  struct Unauthorized {
    bytes32 role;
    address caller;
  }

  struct Accounts {
    address account0;
    address account1;
    address account2;
  }

  struct RevokerChange {
    bytes32 role;
    bytes32 roleRevoker;
  }

  struct RevokerPair {
    bytes32 role;
    bytes32 roleRevoker;
    address holder;
    address target;
  }

  SimpleManagement public management;

  bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
  bytes32 internal constant GUARDIAN_ROLE = KSRoles.GUARDIAN_ROLE;
  bytes32 internal constant OPERATOR_ROLE = KSRoles.OPERATOR_ROLE;

  address internal admin = makeAddr('admin');
  address internal guardian = makeAddr('guardian');
  address internal alice = makeAddr('alice');

  function setUp() public virtual {
    management = new SimpleManagement(admin, _toArray(guardian));
  }

  function _toArray(address account) internal pure returns (address[] memory accounts) {
    accounts = new address[](1);
    accounts[0] = account;
  }

  function _toArray(address account0, address account1, address account2)
    internal
    pure
    returns (address[] memory accounts)
  {
    accounts = new address[](3);
    accounts[0] = account0;
    accounts[1] = account1;
    accounts[2] = account2;
  }

  /// @dev The needed roles reported for a role whose revoker is unset, both reading as the admin
  function _unsetNeededRoles() internal pure returns (bytes32[] memory) {
    return new bytes32[](2);
  }
}

contract ManagementSimpleDeploymentTest is ManagementSimpleBase {
  /// forge-config: default.fuzz.runs = 20
  function test_constructor(Deployment memory c) public {
    vm.assume(c.initialDefaultAdmin != address(0));
    vm.assume(c.initialGuardian != address(0));

    SimpleManagement deployed =
      new SimpleManagement(c.initialDefaultAdmin, _toArray(c.initialGuardian));

    assertEq(deployed.DEFAULT_ADMIN_ROLE(), DEFAULT_ADMIN_ROLE);
    assertEq(deployed.owner(), c.initialDefaultAdmin);
    assertTrue(deployed.hasRole(DEFAULT_ADMIN_ROLE, c.initialDefaultAdmin));
    assertTrue(deployed.hasRole(GUARDIAN_ROLE, c.initialGuardian));
    assertFalse(deployed.paused());
  }

  function test_constructor_revertsOnZeroDefaultAdmin() public {
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
    new SimpleManagement(address(0), new address[](0));
  }

  function test_constructor_withoutGuardians() public {
    SimpleManagement deployed = new SimpleManagement(admin, new address[](0));

    assertFalse(deployed.hasRole(GUARDIAN_ROLE, guardian));
    assertTrue(deployed.hasRole(DEFAULT_ADMIN_ROLE, admin));
  }

  function test_constructor_withDuplicateGuardians() public {
    SimpleManagement deployed = new SimpleManagement(admin, _toArray(guardian, guardian, guardian));

    assertTrue(deployed.hasRole(GUARDIAN_ROLE, guardian));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_supportsInterface(bytes4 interfaceId) public view {
    vm.assume(interfaceId != type(IAccessControl).interfaceId);
    vm.assume(interfaceId != type(IERC165).interfaceId);

    assertTrue(management.supportsInterface(type(IAccessControl).interfaceId));
    assertTrue(management.supportsInterface(type(IERC165).interfaceId));
    assertFalse(management.supportsInterface(interfaceId));
  }
}

contract ManagementSimpleDefaultAdminRoleTest is ManagementSimpleBase {
  /// forge-config: default.fuzz.runs = 20
  function test_hasRole_tracksOwner(address account) public view {
    assertEq(management.hasRole(DEFAULT_ADMIN_ROLE, account), account == admin);
    assertFalse(management.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_getRoleAdmin_isDefaultAdminRole(bytes32 role) public view {
    assertEq(management.getRoleAdmin(role), DEFAULT_ADMIN_ROLE);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_grantRole_revertsOnDefaultAdminRole(address account) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_revertsOnDefaultAdminRole(address account) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

  function test_renounceRole_revertsOnDefaultAdminRole() public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.renounceRole(DEFAULT_ADMIN_ROLE, admin);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_batchGrantRole_revertsOnDefaultAdminRole(Accounts memory c) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);
    management.batchGrantRole(DEFAULT_ADMIN_ROLE, _toArray(c.account0, c.account1, c.account2));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_batchRevokeRole_revertsOnDefaultAdminRole(Accounts memory c) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);
    management.batchRevokeRole(DEFAULT_ADMIN_ROLE, _toArray(c.account0, c.account1, c.account2));
  }
}

contract ManagementSimpleOwnershipTest is ManagementSimpleBase {
  /// forge-config: default.fuzz.runs = 20
  function test_transferOwnership(address newOwner) public {
    vm.assume(newOwner != address(0));
    vm.assume(newOwner != admin);

    vm.expectEmit(true, true, true, true, address(management));
    emit Ownable.OwnershipTransferred(admin, newOwner);

    vm.prank(admin);
    management.transferOwnership(newOwner);

    assertEq(management.owner(), newOwner);
    assertTrue(management.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(management.hasRole(DEFAULT_ADMIN_ROLE, admin));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_transferOwnership_revertsOnUnauthorizedAccount(address caller) public {
    vm.assume(caller != admin);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));

    vm.prank(caller);
    management.transferOwnership(alice);
  }

  function test_transferOwnership_revertsOnZeroAddress() public {
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));

    vm.prank(admin);
    management.transferOwnership(address(0));
  }

  function test_renounceOwnership() public {
    vm.expectEmit(true, true, true, true, address(management));
    emit Ownable.OwnershipTransferred(admin, address(0));

    vm.prank(admin);
    management.renounceOwnership();

    assertEq(management.owner(), address(0));
    assertFalse(management.hasRole(DEFAULT_ADMIN_ROLE, admin));
    assertFalse(management.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_renounceOwnership_revertsOnUnauthorizedAccount(address caller) public {
    vm.assume(caller != admin);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));

    vm.prank(caller);
    management.renounceOwnership();
  }

  /// @dev Renouncing ownership leaves nobody able to unpause or to administer roles
  function test_renounceOwnership_isTerminal() public {
    vm.startPrank(admin);
    management.pause();
    management.renounceOwnership();
    vm.stopPrank();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, admin, DEFAULT_ADMIN_ROLE
      )
    );
    vm.prank(admin);
    management.unpause();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, admin, DEFAULT_ADMIN_ROLE
      )
    );
    vm.prank(admin);
    management.grantRole(OPERATOR_ROLE, alice);

    assertTrue(management.paused());
  }
}

contract ManagementSimpleRoleTest is ManagementSimpleBase {
  /// forge-config: default.fuzz.runs = 20
  function test_grantRole(RoleGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(!(c.role == GUARDIAN_ROLE && c.account == guardian));

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleGranted(c.role, c.account, admin);

    vm.prank(admin);
    management.grantRole(c.role, c.account);

    assertTrue(management.hasRole(c.role, c.account));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_grantRole_revertsOnUnauthorizedAccount(Unauthorized memory c) public {
    vm.assume(c.caller != admin);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, c.caller, DEFAULT_ADMIN_ROLE
      )
    );

    vm.prank(c.caller);
    management.grantRole(c.role, alice);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_grantRole_isIdempotent(RoleGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);

    vm.prank(admin);
    management.grantRole(c.role, c.account);

    vm.recordLogs();
    vm.prank(admin);
    management.grantRole(c.role, c.account);

    assertEq(vm.getRecordedLogs().length, 0);
    assertTrue(management.hasRole(c.role, c.account));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_renounceRole(RoleGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.account != address(0));

    vm.prank(admin);
    management.grantRole(c.role, c.account);

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleRevoked(c.role, c.account, c.account);

    vm.prank(c.account);
    management.renounceRole(c.role, c.account);

    assertFalse(management.hasRole(c.role, c.account));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_renounceRole_revertsOnBadConfirmation(Unauthorized memory c) public {
    vm.assume(c.caller != alice);

    vm.expectRevert(IAccessControl.AccessControlBadConfirmation.selector);

    vm.prank(c.caller);
    management.renounceRole(c.role, alice);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_batchGrantRole(BatchGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);

    management.batchGrantRole(c.role, _toArray(c.account0, c.account1, c.account2));

    assertTrue(management.hasRole(c.role, c.account0));
    assertTrue(management.hasRole(c.role, c.account1));
    assertTrue(management.hasRole(c.role, c.account2));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_batchRevokeRole(BatchGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);

    address[] memory accounts = _toArray(c.account0, c.account1, c.account2);
    management.batchGrantRole(c.role, accounts);

    management.batchRevokeRole(c.role, accounts);

    assertFalse(management.hasRole(c.role, c.account0));
    assertFalse(management.hasRole(c.role, c.account1));
    assertFalse(management.hasRole(c.role, c.account2));
  }

  function test_batchRole_withoutAccounts() public {
    vm.recordLogs();

    management.batchGrantRole(OPERATOR_ROLE, new address[](0));
    management.batchRevokeRole(OPERATOR_ROLE, new address[](0));

    assertEq(vm.getRecordedLogs().length, 0);
  }
}

contract ManagementSimpleRoleRevokerTest is ManagementSimpleBase {
  /// forge-config: default.fuzz.runs = 20
  function test_roleRevokers_defaultsToDefaultAdminRole(bytes32 role) public view {
    assertEq(management.roleRevokers(role), DEFAULT_ADMIN_ROLE);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker(RevokerChange memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.role != OPERATOR_ROLE);
    vm.assume(c.roleRevoker != c.role);

    vm.expectEmit(true, true, true, true, address(management));
    emit IManagementSimple.RoleRevokerChanged(c.role, DEFAULT_ADMIN_ROLE, c.roleRevoker);

    vm.prank(admin);
    management.setRoleRevoker(c.role, c.roleRevoker);
    assertEq(management.roleRevokers(c.role), c.roleRevoker);

    vm.expectEmit(true, true, true, true, address(management));
    emit IManagementSimple.RoleRevokerChanged(c.role, c.roleRevoker, OPERATOR_ROLE);

    vm.prank(admin);
    management.setRoleRevoker(c.role, OPERATOR_ROLE);
    assertEq(management.roleRevokers(c.role), OPERATOR_ROLE);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker_revertsOnSameRole(bytes32 role) public {
    vm.assume(role != DEFAULT_ADMIN_ROLE);

    vm.expectRevert(IManagementSimple.SelfRoleRevokerNotAllowed.selector);

    vm.prank(admin);
    management.setRoleRevoker(role, role);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker_revertsOnDefaultAdminRole(bytes32 roleRevoker) public {
    vm.expectRevert(IManagementSimple.DefaultAdminRoleActionNotAllowed.selector);

    vm.prank(admin);
    management.setRoleRevoker(DEFAULT_ADMIN_ROLE, roleRevoker);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_setRoleRevoker_revertsOnUnauthorizedAccount(Unauthorized memory c) public {
    vm.assume(c.caller != admin);
    vm.assume(c.role != OPERATOR_ROLE);

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, c.caller, DEFAULT_ADMIN_ROLE
      )
    );

    vm.prank(c.caller);
    management.setRoleRevoker(c.role, OPERATOR_ROLE);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_byRevokerRoleHolder(RevokerPair memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.roleRevoker != DEFAULT_ADMIN_ROLE);
    vm.assume(c.roleRevoker != c.role);
    vm.assume(c.holder != admin);

    vm.startPrank(admin);
    management.setRoleRevoker(c.role, c.roleRevoker);
    management.grantRole(c.role, c.target);
    management.grantRole(c.roleRevoker, c.holder);
    vm.stopPrank();

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleRevoked(c.role, c.target, c.holder);

    vm.prank(c.holder);
    management.revokeRole(c.role, c.target);

    assertFalse(management.hasRole(c.role, c.target));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_byDefaultAdmin(RoleGrant memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);

    vm.startPrank(admin);
    management.grantRole(c.role, c.account);

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleRevoked(c.role, c.account, admin);

    management.revokeRole(c.role, c.account);
    vm.stopPrank();

    assertFalse(management.hasRole(c.role, c.account));
  }

  /// @dev The admin role arm authorizes even when the configured revoker role is held elsewhere
  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_byDefaultAdminWithConfiguredRevoker(RevokerPair memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.roleRevoker != DEFAULT_ADMIN_ROLE);
    vm.assume(c.roleRevoker != c.role);
    vm.assume(c.holder != admin);

    vm.startPrank(admin);
    management.setRoleRevoker(c.role, c.roleRevoker);
    management.grantRole(c.role, c.target);
    management.grantRole(c.roleRevoker, c.holder);
    vm.stopPrank();

    assertFalse(management.hasRole(c.roleRevoker, admin));

    vm.expectEmit(true, true, true, true, address(management));
    emit IAccessControl.RoleRevoked(c.role, c.target, admin);

    vm.prank(admin);
    management.revokeRole(c.role, c.target);

    assertFalse(management.hasRole(c.role, c.target));
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_revertsWithConfiguredRevokerInPayload(Unauthorized memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.role != OPERATOR_ROLE);
    vm.assume(c.caller != admin);

    vm.startPrank(admin);
    management.setRoleRevoker(c.role, OPERATOR_ROLE);
    management.grantRole(c.role, alice);
    vm.stopPrank();

    bytes32[] memory neededRoles = new bytes32[](2);
    neededRoles[0] = OPERATOR_ROLE;
    neededRoles[1] = DEFAULT_ADMIN_ROLE;

    vm.expectRevert(
      abi.encodeWithSelector(IManagementSimple.UnauthorizedAccount.selector, c.caller, neededRoles)
    );

    vm.prank(c.caller);
    management.revokeRole(c.role, alice);
  }

  /// forge-config: default.fuzz.runs = 20
  function test_revokeRole_revertsOnUnauthorizedAccount(Unauthorized memory c) public {
    vm.assume(c.role != DEFAULT_ADMIN_ROLE);
    vm.assume(c.caller != admin);

    vm.prank(admin);
    management.grantRole(c.role, alice);

    vm.expectRevert(
      abi.encodeWithSelector(
        IManagementSimple.UnauthorizedAccount.selector, c.caller, _unsetNeededRoles()
      )
    );

    vm.prank(c.caller);
    management.revokeRole(c.role, alice);
  }
}

contract ManagementSimplePausableTest is ManagementSimpleBase {
  function test_pause_byGuardian() public {
    vm.expectEmit(true, true, true, true, address(management));
    emit Pausable.Paused(guardian);

    vm.prank(guardian);
    management.pause();

    assertTrue(management.paused());
  }

  function test_pause_byDefaultAdmin() public {
    vm.expectEmit(true, true, true, true, address(management));
    emit Pausable.Paused(admin);

    vm.prank(admin);
    management.pause();

    assertTrue(management.paused());
  }

  /// forge-config: default.fuzz.runs = 20
  function test_pause_byBatchGrantedGuardian(address account) public {
    vm.assume(account != admin);
    vm.assume(account != guardian);

    management.batchGrantRole(GUARDIAN_ROLE, _toArray(account));

    vm.expectEmit(true, true, true, true, address(management));
    emit Pausable.Paused(account);

    vm.prank(account);
    management.pause();

    assertTrue(management.paused());
  }

  /// forge-config: default.fuzz.runs = 20
  function test_pause_revertsOnUnauthorizedAccount(address caller) public {
    vm.assume(caller != admin);
    vm.assume(caller != guardian);

    bytes32[] memory neededRoles = new bytes32[](2);
    neededRoles[0] = GUARDIAN_ROLE;
    neededRoles[1] = DEFAULT_ADMIN_ROLE;

    vm.expectRevert(
      abi.encodeWithSelector(IManagementSimple.UnauthorizedAccount.selector, caller, neededRoles)
    );

    vm.prank(caller);
    management.pause();
  }

  function test_pause_revertsWhenPaused() public {
    vm.prank(guardian);
    management.pause();

    vm.expectRevert(Pausable.EnforcedPause.selector);

    vm.prank(guardian);
    management.pause();
  }

  function test_unpause() public {
    vm.prank(guardian);
    management.pause();

    vm.expectEmit(true, true, true, true, address(management));
    emit Pausable.Unpaused(admin);

    vm.prank(admin);
    management.unpause();

    assertFalse(management.paused());
  }

  /// forge-config: default.fuzz.runs = 20
  function test_unpause_revertsOnUnauthorizedAccount(address caller) public {
    vm.assume(caller != admin);

    vm.prank(guardian);
    management.pause();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, caller, DEFAULT_ADMIN_ROLE
      )
    );

    vm.prank(caller);
    management.unpause();
  }

  /// @dev A guardian may pause but may not unpause
  function test_unpause_revertsOnGuardian() public {
    vm.prank(guardian);
    management.pause();

    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, guardian, DEFAULT_ADMIN_ROLE
      )
    );

    vm.prank(guardian);
    management.unpause();
  }

  function test_unpause_revertsWhenNotPaused() public {
    vm.expectRevert(Pausable.ExpectedPause.selector);

    vm.prank(admin);
    management.unpause();
  }
}
