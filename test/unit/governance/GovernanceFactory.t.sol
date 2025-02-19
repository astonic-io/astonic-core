// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable func-name-mixedcase, max-line-length

import { GovernanceTest } from "./GovernanceTest.sol";
import { addresses, uints } from "contracts/libraries/Array.sol";

import { ProxyAdmin } from "openzeppelin-contracts-next/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "openzeppelin-contracts-next/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { LockingHarness } from "test/utils/harnesses/LockingHarness.sol";
import { GovernanceFactoryHarness } from "test/utils/harnesses/GovernanceFactoryHarness.t.sol";

import { GovernanceFactory } from "contracts/governance/GovernanceFactory.sol";
import { AstonicGovernor } from "contracts/governance/AstonicGovernor.sol";
import { TimelockController } from "contracts/governance/TimelockController.sol";

contract GovernanceFactoryTest is GovernanceTest {
  GovernanceFactoryHarness public factory;

  address public astonicLabsMultiSig = makeAddr("AstonicLabsVestingMultisig");
  address public watchdogMultiSig = makeAddr("WatchdogMultisig");
  address public fractalSigner = makeAddr("FractalSigner");

  bytes32 public airgrabMerkleRoot = 0x945d83ced94efc822fed712b4c4694b4e1129607ec5bbd2ab971bb08dca4d809; // Mock root

  // If we started at block 0, Locking.getWeek() would return 0 and
  // the following line would revert with an underflow:
  // https://github.com/planq-network/astonic-core/blob/2075c83f3b90465f988195dd746c9992614001bc/contracts/governance/GovernanceFactory.sol#L201
  function setUp() public {
    skip(30 days);
    vm.roll(30 * BLOCKS_DAY);
  }

  function _newFactory() internal {
    factory = new GovernanceFactoryHarness(owner);
  }

  function _createGovernance() internal {
    GovernanceFactory.AstonicTokenAllocationParams memory allocationParams = GovernanceFactory
      .AstonicTokenAllocationParams({
        airgrabAllocation: 50,
        astonicTreasuryAllocation: 100,
        additionalAllocationRecipients: addresses(astonicLabsMultiSig),
        additionalAllocationAmounts: uints(200)
      });

    factory.createGovernance(watchdogMultiSig, allocationParams);
  }

  // ========================================
  // GovernanceFactory.constructor
  // ========================================
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function test_constructor_transfersOwnership() public {
    vm.prank(alice);
    vm.expectEmit(true, true, true, true);
    emit OwnershipTransferred(alice, owner);

    _newFactory();

    assertEq(address(factory.owner()), owner);
  }

  // ========================================
  // GovernanceFactory.createGovernance
  // ========================================
  /// @notice setup for initialize tests
  modifier i_setUp() {
    _newFactory();
    _;
  }

  //
  // ✅ Positive Tests
  //
  function test_createGovernance_whenCallerOwner_shouldDeployAllGovernanceContracts() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    // Check that the contracts have been deployed
    assertFalse(address(factory.proxyAdmin()) == address(0), "ProxyAdmin not deployed");
    assertFalse(address(factory.emission()) == address(0), "Emission not deployed");
    assertFalse(address(factory.astonicToken()) == address(0), "AstonicToken not deployed");
    assertFalse(address(factory.airgrab()) == address(0), "Airgrab not deployed");
    assertFalse(address(factory.locking()) == address(0), "Locking not deployed");
    assertFalse(address(factory.governanceTimelock()) == address(0), "TimelockController not deployed");
    assertFalse(address(factory.astonicGovernor()) == address(0), "AstonicGovernor not deployed");
  }

  function test_createGovernance_shouldTransferOwnershipToGovernanceTimelock() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    address governanceTimelock = address(factory.governanceTimelock());
    assertEq(factory.emission().owner(), governanceTimelock);
    assertEq(factory.locking().owner(), governanceTimelock);
    assertEq(factory.proxyAdmin().owner(), governanceTimelock);
  }

  function test_createGovernance_whenAdditionalAllocationRecipients_shouldCombineRecipients() public i_setUp {
    uint256 supply = 1_000_000_000 * 10 ** 18;
    GovernanceFactory.AstonicTokenAllocationParams memory allocationParams = GovernanceFactory
      .AstonicTokenAllocationParams({
        airgrabAllocation: 50,
        astonicTreasuryAllocation: 100,
        additionalAllocationRecipients: addresses(makeAddr("Recipient1"), makeAddr("Recipient2"), astonicLabsMultiSig),
        additionalAllocationAmounts: uints(55, 50, 80)
      });

    vm.prank(owner);
    factory.createGovernance(watchdogMultiSig, allocationParams);

    assertEq(factory.astonicToken().balanceOf(makeAddr("Recipient1")), (supply * 55) / 1000);
    assertEq(factory.astonicToken().balanceOf(makeAddr("Recipient2")), (supply * 50) / 1000);
    assertEq(factory.astonicToken().balanceOf(astonicLabsMultiSig), (supply * 80) / 1000);
    assertEq(factory.astonicToken().balanceOf(address(factory.airgrab())), (supply * 50) / 1000);
    assertEq(factory.astonicToken().balanceOf(address(factory.governanceTimelock())), (supply * 100) / 1000);
  }

  //
  // ❌ Negative Tests
  //
  function test_createGovernance_whenCallerOwner_shouldNotDeployMoreContractsThanExpected() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    uint256 nonce = vm.getNonce(address(factory));
    assertEq(nonce, 12); // Confirms that no more contracts than the expected 12 have been deployed
  }

  function test_createGovernance_whenCallerNotOwner_shouldRevert() public i_setUp {
    vm.expectRevert("Ownable: caller is not the owner");
    _createGovernance();
  }

  function test_createGovernance_whenCalledTwice_shouldRevert() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    vm.prank(owner);
    vm.expectRevert("Factory: governance already created");
    _createGovernance();
  }

  // ========================================
  // Upgradeability Test: Locking
  // ========================================
  function test_createGovernance_lockingShouldBeUpgradeable() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    ProxyAdmin proxyAdmin = factory.proxyAdmin();
    ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(address(factory.locking()));

    assertEq(
      proxyAdmin.getProxyAdmin(proxy),
      address(factory.proxyAdmin()),
      "Factory: lockingProxy should have a proxyAdmin"
    );

    // we can cheat and calculate the address of the implementation contract via addressForNonce()
    address precalculatedAddress = factory.exposed_addressForNonce(6);
    address initialImpl = proxyAdmin.getProxyImplementation(proxy);
    assertEq(initialImpl, precalculatedAddress, "Factory: lockingProxy should have an implementation");

    // deploy and upgrade to new implementation
    LockingHarness newImplContract = new LockingHarness();
    vm.prank(address(factory.governanceTimelock()));
    proxyAdmin.upgrade(proxy, address(newImplContract));

    address newImpl = proxyAdmin.getProxyImplementation(proxy);
    assertFalse(initialImpl == newImpl, "Factory: LockingProxy should have a new implementation");
    assertTrue(newImpl == address(newImplContract), "Factory: LockingProxy implementation should equal newImpl");
  }

  // ========================================
  // Upgradeability Test: Governance Timelock
  // ========================================
  function test_createGovernance_governanceTimelockShouldBeUpgradeable() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    ProxyAdmin proxyAdmin = factory.proxyAdmin();
    ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(address(factory.governanceTimelock()));

    assertEq(
      proxyAdmin.getProxyAdmin(proxy),
      address(factory.proxyAdmin()),
      "Factory: governanceTimelock should have a proxyAdmin"
    );

    // we can cheat and calculate the address of the implementation contract via addressForNonce()
    address precalculatedAddress = factory.exposed_addressForNonce(8);
    address initialImpl = proxyAdmin.getProxyImplementation(proxy);
    assertEq(initialImpl, precalculatedAddress, "Factory: governanceTimelockProxy should have an implementation");

    // deploy and upgrade to new implementation
    TimelockController newImplContract = new TimelockController();
    vm.prank(address(factory.governanceTimelock()));
    proxyAdmin.upgrade(proxy, address(newImplContract));

    address newImpl = proxyAdmin.getProxyImplementation(proxy);
    assertFalse(initialImpl == newImpl, "Factory: governanceTimelockProxy should have a new implementation");
    assertTrue(
      newImpl == address(newImplContract),
      "Factory: governanceTimelockProxy implementation should equal newImpl"
    );
  }

  // ==================================
  // Upgradeability Test: AstonicGovernor
  // ==================================
  function test_createGovernance_astonicGovernorShouldBeUpgradeable() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    ProxyAdmin proxyAdmin = factory.proxyAdmin();
    ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(address(factory.astonicGovernor()));

    assertEq(
      proxyAdmin.getProxyAdmin(proxy),
      address(factory.proxyAdmin()),
      "Factory: astonicGovernorProxy should have a proxyAdmin"
    );

    // we can cheat and calculate the address of the implementation contract via addressForNonce()
    address precalculatedAddress = factory.exposed_addressForNonce(10);
    address initialImpl = proxyAdmin.getProxyImplementation(proxy);
    assertEq(initialImpl, precalculatedAddress, "Factory: astonicGovernorProxy should have an implementation");

    // deploy and upgrade to new implementation
    AstonicGovernor newImplContract = new AstonicGovernor();
    vm.prank(address(factory.governanceTimelock()));
    proxyAdmin.upgrade(proxy, address(newImplContract));

    address newImpl = proxyAdmin.getProxyImplementation(proxy);
    assertFalse(initialImpl == newImpl, "Factory: astonicGovernorProxy should have a new implementation");
    assertTrue(newImpl == address(newImplContract), "Factory: astonicGovernorProxy implementation should equal newImpl");
  }

  // ========================================
  // Upgradeability Test: Immutable Contracts
  // ========================================
  function test_createGovernance_otherContractsShouldBeImmutable() public i_setUp {
    vm.prank(owner);
    _createGovernance();

    ProxyAdmin proxyAdmin = factory.proxyAdmin();

    ITransparentUpgradeableProxy astonicTokenNotAProxy = ITransparentUpgradeableProxy(address(factory.astonicToken()));
    vm.expectRevert();
    proxyAdmin.getProxyAdmin(astonicTokenNotAProxy);

    ITransparentUpgradeableProxy airgrabNotAProxy = ITransparentUpgradeableProxy(address(factory.airgrab()));
    vm.expectRevert();
    proxyAdmin.getProxyAdmin(airgrabNotAProxy);
  }

  // ==================================
  // GovernanceFactory.addressForNonce
  // ==================================
  function testFuzz_addressForNonce_whenNoncesAreIdentical_shouldReturnTheSameAddress(uint256 nonce) public i_setUp {
    address account0 = factory.exposed_addressForNonce(nonce);
    address account1 = factory.exposed_addressForNonce(nonce);
    assertTrue(account0 == account1, "addressForNonce: Should return same address for same nonce");
  }

  function testFuzz_addressForNonce_whenNoncesAreDifferent_shouldReturnDifferentAddresses(
    uint256 nonce1,
    uint256 nonce2
  ) public i_setUp {
    // We can only safely get 256 unique addresses because we're using
    // a uint8 nonce in the function `bytes1(uint8(nonce))`
    nonce1 = bound(nonce1, 0, 255);
    nonce2 = bound(nonce2, 0, 255);
    vm.assume(nonce1 != nonce2);
    address account1 = factory.exposed_addressForNonce(nonce1);
    address account2 = factory.exposed_addressForNonce(nonce2);
    assertFalse(account1 == account2, "addressForNonce: Should return different addresses for different nonces");
  }
}
