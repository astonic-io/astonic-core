// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable func-name-mixedcase, max-line-length, max-states-count

import { addresses, uints } from "contracts/libraries/Array.sol";
import { Vm } from "forge-std/Vm.sol";

import { AstonicGovernor } from "contracts/governance/AstonicGovernor.sol";
import { GovernanceFactory } from "contracts/governance/GovernanceFactory.sol";
import { AstonicToken } from "contracts/governance/AstonicToken.sol";
import { Airgrab } from "contracts/governance/Airgrab.sol";
import { Emission } from "contracts/governance/Emission.sol";
import { Locking } from "contracts/governance/locking/Locking.sol";
import { TimelockController } from "contracts/governance/TimelockController.sol";

import { VmExtension } from "test/utils/VmExtension.sol";
import { GovernanceTest } from "test/unit/governance/GovernanceTest.sol";
import { Proposals } from "./Proposals.sol";

import { ProxyAdmin } from "openzeppelin-contracts-next/contracts/proxy/transparent/ProxyAdmin.sol";

contract GovernanceGasTest is GovernanceTest {
  using VmExtension for Vm;

  GovernanceFactory public factory;

  ProxyAdmin public proxyAdmin;
  AstonicToken public astonicToken;
  Emission public emission;
  Airgrab public airgrab;
  TimelockController public governanceTimelock;
  address public governanceTimelockAddress;
  AstonicGovernor public astonicGovernor;
  Locking public locking;

  address public planqGovernance = makeAddr("PlanqGovernance");
  address public watchdogMultisig = makeAddr("WatchdogMultisig");
  address public astonicLabsMultisig = makeAddr("AstonicLabsMultisig");
  address public fractalSigner = makeAddr("FractalSigner");

  bytes32 public merkleRoot = 0x945d83ced94efc822fed712b4c4694b4e1129607ec5bbd2ab971bb08dca4d809;

  uint256 public viewCallGas = 30_000;
  uint256 public proposalCreationGas = 500_000;
  uint256 public proposalQueueGas = 200_000;
  uint256 public proposalExecutionGas = 200_000;
  uint256 public voteGas = 100_000;

  modifier s_attack() {
    vm.prank(governanceTimelockAddress);
    astonicToken.transfer(alice, 100_000e18);

    vm.prank(governanceTimelockAddress);
    astonicToken.transfer(bob, 100_000e18);

    vm.prank(alice);
    locking.lock(alice, alice, 20_000e18, 1, 103);

    vm.prank(bob);
    locking.lock(bob, bob, 1500e18, 1, 103);

    vm.timeTravel(BLOCKS_DAY);

    for (uint256 i = 0; i < 50_000; i++) {
      vm.prank(alice);
      locking.lock(alice, bob, 1e18, 1, 103);
    }
    _;
  }

  function setUp() public {
    vm.roll(21871402); // (Oct-11-2023 WED 12:00:01 PM +UTC)
    vm.warp(1697025601); // (Oct-11-2023 WED 12:00:01 PM +UTC)

    GovernanceFactory.AstonicTokenAllocationParams memory allocationParams = GovernanceFactory
      .AstonicTokenAllocationParams({
        airgrabAllocation: 50,
        astonicTreasuryAllocation: 100,
        additionalAllocationRecipients: addresses(address(astonicLabsMultisig)),
        additionalAllocationAmounts: uints(200)
      });

    vm.prank(owner);
    factory = new GovernanceFactory(planqGovernance);

    vm.prank(planqGovernance);
    factory.createGovernance(watchdogMultisig, allocationParams);
    proxyAdmin = factory.proxyAdmin();
    astonicToken = factory.astonicToken();
    emission = factory.emission();
    airgrab = factory.airgrab();
    governanceTimelock = factory.governanceTimelock();
    astonicGovernor = factory.astonicGovernor();
    locking = factory.locking();

    // Without this cast, tests do not work as expected
    // It causes a yul exception about memory safety
    governanceTimelockAddress = address(governanceTimelock);

    vm.prank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    vm.prank(bob);
    astonicToken.approve(address(locking), type(uint256).max);
  }

  // PoC from: https://github.com/sherlock-audit/2024-02-astonic-judging/issues/4
  function test_totalSupply_whenUsedWith50_000Locks_shouldCostReasonableGas() public s_attack {
    uint256 gasLeftBefore = gasleft();
    locking.totalSupply();
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    gasLeftBefore = gasleft();
    locking.totalSupply();
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    gasLeftBefore = gasleft();
    locking.totalSupply();
    assertLt(gasLeftBefore - gasleft(), viewCallGas);
  }

  // PoC from https://github.com/sherlock-audit/2024-02-astonic-judging/issues/2
  function test_getVotes_whenUsedWith50_000Locks_shouldCostReasonableGas() public s_attack {
    uint256 gasLeftBefore = gasleft();
    locking.getVotes(bob);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    gasLeftBefore = gasleft();
    locking.getVotes(bob);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    gasLeftBefore = gasleft();
    locking.getVotes(bob);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);
  }

  function test_getPastVotes_whenUsedWith50_000Locks_shouldCostReasonableGas() public s_attack {
    uint256 gasLeftBefore = gasleft();
    locking.getPastVotes(bob, block.number - BLOCKS_DAY);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    vm.timeTravel(BLOCKS_WEEK);

    gasLeftBefore = gasleft();
    locking.getPastVotes(bob, block.number - 3 * BLOCKS_DAY);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.timeTravel(BLOCKS_DAY);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    vm.timeTravel(BLOCKS_WEEK);

    gasLeftBefore = gasleft();
    locking.getPastVotes(bob, block.number - 2 * BLOCKS_WEEK);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);
  }

  function test_getPastTotalSupply_whenUsedWith50_000Locks_shouldCostReasonableGas() public s_attack {
    uint256 gasLeftBefore = gasleft();
    locking.getPastTotalSupply(block.number - BLOCKS_DAY);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    vm.timeTravel(BLOCKS_WEEK);

    gasLeftBefore = gasleft();
    locking.getPastTotalSupply(block.number - 3 * BLOCKS_DAY);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);

    vm.timeTravel(BLOCKS_DAY);

    vm.startPrank(alice);
    astonicToken.approve(address(locking), type(uint256).max);
    for (uint256 i; i < 1_000; i++) {
      locking.lock(alice, bob, 1e18, 100, 100);
    }
    vm.stopPrank();

    vm.timeTravel(BLOCKS_WEEK);

    gasLeftBefore = gasleft();
    locking.getPastTotalSupply(block.number - 2 * BLOCKS_WEEK);
    assertLt(gasLeftBefore - gasleft(), viewCallGas);
  }

  function test_queueAndExecute_whenUsedWith50_000LocksAndNewLocksInSameBlock_shouldCostReasonableGas()
    public
    s_attack
  {
    address newEmissionTarget = makeAddr("NewEmissionTarget");

    // one more lock in the same block with propose
    vm.prank(alice);
    locking.lock(alice, bob, 1e18, 1, 103);

    uint256 gasLeftBefore = gasleft();
    vm.prank(alice);
    (
      uint256 proposalId,
      address[] memory targets,
      uint256[] memory values,
      bytes[] memory calldatas,
      string memory description
    ) = Proposals._proposeChangeEmissionTarget(astonicGovernor, emission, newEmissionTarget);
    assertLt(gasLeftBefore - gasleft(), proposalCreationGas);

    // ~10 mins
    vm.timeTravel(120);

    // Locking for bob in the same block with castVote
    vm.prank(alice);
    locking.lock(alice, bob, 1e18, 1, 103);

    gasLeftBefore = gasleft();
    vm.prank(alice);
    astonicGovernor.castVote(proposalId, 0);
    assertLt(gasLeftBefore - gasleft(), voteGas);

    gasLeftBefore = gasleft();
    vm.prank(bob);
    astonicGovernor.castVote(proposalId, 1);
    assertLt(gasLeftBefore - gasleft(), voteGas);

    // voting period ends
    vm.timeTravel(BLOCKS_WEEK);

    // Locking in the same block with queue
    vm.prank(alice);
    locking.lock(alice, bob, 1e18, 1, 103);

    gasLeftBefore = gasleft();
    astonicGovernor.queue(targets, values, calldatas, keccak256(bytes(description)));
    assertLt(gasLeftBefore - gasleft(), proposalQueueGas);

    vm.timeTravel(2 * BLOCKS_DAY);

    // Locking in the same block with execute
    vm.prank(alice);
    locking.lock(alice, bob, 1e18, 1, 103);

    gasLeftBefore = gasleft();
    vm.prank(makeAddr("Random"));
    astonicGovernor.execute(targets, values, calldatas, keccak256(bytes(description)));
    assertLt(gasLeftBefore - gasleft(), proposalExecutionGas);
  }

  function test_queueAndExecute_whenUsedWith50_000Locks_shouldCostReasonableGas() public s_attack {
    address newEmissionTarget = makeAddr("NewEmissionTarget");

    uint256 gasLeftBefore = gasleft();
    vm.prank(alice);
    (
      uint256 proposalId,
      address[] memory targets,
      uint256[] memory values,
      bytes[] memory calldatas,
      string memory description
    ) = Proposals._proposeChangeEmissionTarget(astonicGovernor, emission, newEmissionTarget);
    assertLt(gasLeftBefore - gasleft(), proposalCreationGas);

    // ~10 mins
    vm.timeTravel(120);

    vm.prank(alice);
    locking.lock(alice, alice, 1e18, 1, 103);

    // ~10 mins
    vm.timeTravel(120);

    gasLeftBefore = gasleft();
    vm.prank(alice);
    astonicGovernor.castVote(proposalId, 0);
    assertLt(gasLeftBefore - gasleft(), voteGas);

    // ~10 mins
    vm.timeTravel(120);

    gasLeftBefore = gasleft();
    vm.prank(bob);
    astonicGovernor.castVote(proposalId, 1);
    assertLt(gasLeftBefore - gasleft(), voteGas);

    // voting period ends
    vm.timeTravel(BLOCKS_WEEK);

    gasLeftBefore = gasleft();
    astonicGovernor.queue(targets, values, calldatas, keccak256(bytes(description)));
    assertLt(gasLeftBefore - gasleft(), proposalQueueGas);

    vm.timeTravel(2 * BLOCKS_DAY);

    gasLeftBefore = gasleft();
    vm.prank(makeAddr("Random"));
    astonicGovernor.execute(targets, values, calldatas, keccak256(bytes(description)));
    assertLt(gasLeftBefore - gasleft(), proposalExecutionGas);
  }
}
