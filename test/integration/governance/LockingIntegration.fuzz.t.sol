// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable func-name-mixedcase, max-line-length, max-states-count

import { Vm } from "forge-std/Vm.sol";
import { addresses, uints } from "contracts/libraries/Array.sol";

import { VmExtension } from "test/utils/VmExtension.sol";
import { GovernanceTest } from "test/unit/governance/GovernanceTest.sol";

import { GovernanceFactory } from "contracts/governance/GovernanceFactory.sol";
import { AstonicToken } from "contracts/governance/AstonicToken.sol";
import { Locking } from "contracts/governance/locking/Locking.sol";
import { TimelockController } from "contracts/governance/TimelockController.sol";

/**
 * @title Fuzz Testing for Locking Integration
 * @dev Fuzz tests to ensure the locking mechanism integrates correctly with the governance system, providing the expected voting power based on token lock amount and duration.
 */
contract FuzzLockingIntegrationTest is GovernanceTest {
  using VmExtension for Vm;

  GovernanceFactory public factory;

  AstonicToken public astonicToken;
  TimelockController public governanceTimelock;
  Locking public locking;

  address public planqGovernance = makeAddr("PlanqGovernance");
  address public watchdogMultisig = makeAddr("WatchdogMultisig");
  address public astonicLabsMultisig = makeAddr("AstonicLabsMultisig");
  address public fractalSigner = makeAddr("FractalSigner");

  bytes32 public merkleRoot = bytes32("MockMerkleRoot");

  function setUp() public {
    vm.roll(21871402); // (Oct-11-2023 WED 12:00:01 PM +UTC)
    vm.warp(1697025601); // (Oct-11-2023 WED 12:00:01 PM +UTC)

    vm.prank(owner);
    factory = new GovernanceFactory(planqGovernance);

    GovernanceFactory.AstonicTokenAllocationParams memory allocationParams = GovernanceFactory
      .AstonicTokenAllocationParams({
        airgrabAllocation: 50,
        astonicTreasuryAllocation: 100,
        additionalAllocationRecipients: addresses(address(astonicLabsMultisig)),
        additionalAllocationAmounts: uints(200)
      });

    vm.prank(planqGovernance);
    factory.createGovernance(watchdogMultisig, allocationParams);
    astonicToken = factory.astonicToken();
    governanceTimelock = factory.governanceTimelock();
    locking = factory.locking();

    vm.prank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
  }

  /**
   * @dev Fuzz test to verify correct voting power allocation for locked tokens over a shorter timeframe.
   */
  function test_lock_shouldGiveCorrectVotingPower_whenShorterTimeframe_Fuzz(
    uint96 amount,
    uint32 slope,
    uint32 cliff,
    uint96 period
  ) public {
    amount = uint96(bound(amount, 1e18, astonicToken.balanceOf(address(governanceTimelock))));
    vm.assume(slope >= locking.minSlopePeriod());
    vm.assume(slope <= 104);
    vm.assume(cliff >= locking.minCliffPeriod());
    vm.assume(cliff <= 103);
    vm.assume(period <= 208); // 4 years

    vm.prank(address(governanceTimelock));
    astonicToken.transfer(alice, amount);

    vm.prank(alice);
    locking.lock(alice, alice, amount, slope, cliff);

    assertEq(locking.getVotes(alice), calculateVotes(amount, slope, cliff));

    vm.timeTravel(BLOCKS_WEEK * period);

    uint256 balanceBefore = astonicToken.balanceOf(alice);

    vm.prank(alice);
    locking.withdraw();

    uint256 balanceAfter = astonicToken.balanceOf(alice);

    if (period > cliff) {
      assert(balanceAfter > balanceBefore);
    } else {
      assertEq(balanceAfter, balanceBefore);
    }

    if (period > slope + cliff) {
      assertEq(locking.getVotes(alice), 0);
      assertEq(balanceAfter, amount);
    }
  }

  /**
   * @dev Fuzz test to verify correct voting power allocation for locked tokens over a longer timeframe.
   * Focuses on longer periods to avoid sparse coverage for more frequent usecase: period being < 4 years
   */
  function test_lock_shouldGiveCorrectVotingPower_whenLongerTimeframe_Fuzz(
    uint96 amount,
    uint32 slope,
    uint32 cliff,
    uint96 period
  ) public {
    amount = uint96(bound(amount, 1e18, astonicToken.balanceOf(address(governanceTimelock))));
    vm.assume(slope >= locking.minSlopePeriod());
    vm.assume(slope <= 104);
    vm.assume(cliff >= locking.minCliffPeriod());
    vm.assume(cliff <= 103);
    vm.assume(period <= 2080); // 40 years

    vm.prank(address(governanceTimelock));
    astonicToken.transfer(alice, amount);

    vm.prank(alice);
    locking.lock(alice, alice, amount, slope, cliff);

    assertEq(locking.getVotes(alice), calculateVotes(amount, slope, cliff));

    vm.timeTravel(BLOCKS_WEEK * period);

    uint256 balanceBefore = astonicToken.balanceOf(alice);

    vm.prank(alice);
    locking.withdraw();

    uint256 balanceAfter = astonicToken.balanceOf(alice);

    if (period > cliff) {
      assert(balanceAfter > balanceBefore);
    } else {
      assertEq(balanceAfter, balanceBefore);
    }

    if (period > slope + cliff) {
      assertEq(locking.getVotes(alice), 0);
      assertEq(balanceAfter, amount);
    }
  }

  /**
   * @dev Calculates the expected voting power based on lock amount, slope, and cliff.
   */
  function calculateVotes(uint96 amount, uint32 slope, uint32 cliff) public pure returns (uint96) {
    uint96 cliffSide = (uint96(cliff) * 1e8) / 103;
    uint96 slopeSide = (uint96(slope) * 1e8) / 104;
    uint96 multiplier = cliffSide + slopeSide;
    if (multiplier > 1e8) multiplier = 1e8;

    return uint96((uint256(amount) * uint256(multiplier)) / 1e8);
  }
}
