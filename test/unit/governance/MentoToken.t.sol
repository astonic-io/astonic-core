// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable func-name-mixedcase

import { uints, addresses } from "contracts/libraries/Array.sol";
import { GovernanceTest } from "./GovernanceTest.sol";
import { AstonicToken } from "contracts/governance/AstonicToken.sol";

contract AstonicTokenTest is GovernanceTest {
  event Paused(address account);

  AstonicToken public astonicToken;

  address public astonicLabsMultiSig = makeAddr("astonicLabsMultiSig");
  address public astonicLabsTreasuryTimelock = makeAddr("astonicLabsTreasuryTimelock");
  address public airgrab = makeAddr("airgrab");
  address public governanceTimelock = makeAddr("governanceTimelock");
  address public emission = makeAddr("emission");
  address public locking = makeAddr("locking");

  uint256[] public allocationAmounts = uints(80, 120, 50, 100);
  address[] public allocationRecipients =
    addresses(astonicLabsMultiSig, astonicLabsTreasuryTimelock, airgrab, governanceTimelock);

  modifier notPaused() {
    astonicToken.unpause();
    _;
  }

  function setUp() public {
    astonicToken = new AstonicToken(allocationRecipients, allocationAmounts, emission, locking);
  }

  function test_constructor_whenEmissionIsZero_shouldRevert() public {
    vm.expectRevert("AstonicToken: emission is zero address");
    astonicToken = new AstonicToken(allocationRecipients, allocationAmounts, address(0), locking);
  }

  function test_constructor_whenLockingIsZero_shouldRevert() public {
    vm.expectRevert("AstonicToken: locking is zero address");
    astonicToken = new AstonicToken(allocationRecipients, allocationAmounts, emission, address(0));
  }

  function test_constructor_whenAllocationRecipientsAndAmountsLengthMismatch_shouldRevert() public {
    vm.expectRevert("AstonicToken: recipients and amounts length mismatch");
    astonicToken = new AstonicToken(allocationRecipients, uints(80, 120, 50), emission, locking);
  }

  function test_constructor_whenAllocationRecipientIsZero_shouldRevert() public {
    vm.expectRevert("AstonicToken: allocation recipient is zero address");
    astonicToken = new AstonicToken(
      addresses(astonicLabsMultiSig, astonicLabsTreasuryTimelock, airgrab, address(0)),
      allocationAmounts,
      emission,
      locking
    );
  }

  function test_constructor_whenTotalAllocationExceeds1000_shouldRevert() public {
    vm.expectRevert("AstonicToken: total allocation exceeds 100%");
    astonicToken = new AstonicToken(allocationRecipients, uints(80, 120, 50, 1000), emission, locking);
  }

  function test_constructor_shouldPauseTheContract() public {
    vm.expectEmit(true, true, true, true);
    emit Paused(address(this));
    astonicToken = new AstonicToken(allocationRecipients, uints(80, 120, 50, 100), emission, locking);

    assertEq(astonicToken.paused(), true);
  }

  /// @dev Test the state initialization post-construction of the AstonicToken contract.
  function test_constructor_shouldSetCorrectState() public view {
    assertEq(astonicToken.emission(), emission);
    assertEq(astonicToken.emissionSupply(), EMISSION_SUPPLY);
    assertEq(astonicToken.emittedAmount(), 0);
  }

  /// @dev Test the correct token amounts are minted to respective contracts during initialization.
  function test_constructor_shouldMintCorrectAmounts() public view {
    uint256 astonicLabsMultiSigSupply = astonicToken.balanceOf(astonicLabsMultiSig);
    uint256 astonicLabsTreasurySupply = astonicToken.balanceOf(astonicLabsTreasuryTimelock);
    uint256 airgrabSupply = astonicToken.balanceOf(airgrab);
    uint256 governanceTimelockSupply = astonicToken.balanceOf(governanceTimelock);
    uint256 emissionSupply = astonicToken.balanceOf(emission);

    assertEq(astonicLabsMultiSigSupply, 80_000_000 * 1e18);
    assertEq(astonicLabsTreasurySupply, 120_000_000 * 1e18);
    assertEq(airgrabSupply, 50_000_000 * 1e18);
    assertEq(governanceTimelockSupply, 100_000_000 * 1e18);
    assertEq(emissionSupply, 0);

    assertEq(
      astonicLabsMultiSigSupply + astonicLabsTreasurySupply + airgrabSupply + governanceTimelockSupply + emissionSupply,
      INITIAL_TOTAL_SUPPLY
    );
    assertEq(astonicToken.totalSupply(), INITIAL_TOTAL_SUPPLY);
  }

  /**
   * @dev Test the burn functionality for an individual account.
   * @notice Even though the burn function comes from OpenZeppelin's library,
   * @notice this test assures correct integration.
   */
  function test_burn_shouldBurnTokens() public notPaused {
    uint256 initialBalance = 3e18;
    uint256 burnAmount = 1e18;
    deal(address(astonicToken), alice, initialBalance);

    vm.startPrank(alice);
    vm.expectRevert("ERC20: burn amount exceeds balance");
    astonicToken.burn(initialBalance + 1);

    astonicToken.burn(burnAmount);
    assertEq(astonicToken.balanceOf(alice), initialBalance - burnAmount);
    assertEq(astonicToken.totalSupply(), INITIAL_TOTAL_SUPPLY - burnAmount);
  }

  /**
   * @dev Test the burnFrom functionality considering allowances.
   * @notice Even though the burnFrom function comes from OpenZeppelin's library,
   * @notice this test assures correct integration.
   */
  function test_burnFrom_whenAllowed_shouldBurnTokens() public notPaused {
    uint256 initialBalance = 3e18;
    uint256 burnAmount = 1e18;
    deal(address(astonicToken), alice, initialBalance);

    vm.prank(bob);
    vm.expectRevert("ERC20: insufficient allowance");
    astonicToken.burnFrom(alice, burnAmount);

    vm.prank(alice);
    astonicToken.approve(bob, burnAmount);

    vm.startPrank(bob);
    vm.expectRevert("ERC20: insufficient allowance");
    astonicToken.burnFrom(alice, burnAmount + 1);

    astonicToken.burnFrom(alice, burnAmount);
    assertEq(astonicToken.balanceOf(alice), initialBalance - burnAmount);
    assertEq(astonicToken.totalSupply(), INITIAL_TOTAL_SUPPLY - burnAmount);

    vm.expectRevert("ERC20: insufficient allowance");
    astonicToken.burnFrom(alice, burnAmount);
  }

  /**
   * @dev Tests the mint function's access control mechanism.
   * @dev This test ensures that the mint function can only be called by the emission contract address.
   * Any other address attempting to mint tokens should have the transaction reverted.
   */
  function test_mint_whenNotEmissionContract_shouldRevert() public {
    uint256 mintAmount = 10e18;
    vm.prank(bob);
    vm.expectRevert("AstonicToken: only emission contract");
    astonicToken.mint(alice, mintAmount);
  }

  /**
   * @dev Tests the mint function's behavior when minting amounts that exceed the emission supply.
   * @notice This test ensures that when the mint function is called with an amount that
   * exceeds the total emission supply, the transaction should be reverted.
   */
  function test_mint_whenAmountBiggerThanEmissionSupply_shouldRevert() public notPaused {
    uint256 mintAmount = 10e18;

    vm.startPrank(emission);

    vm.expectRevert("AstonicToken: emission supply exceeded");
    astonicToken.mint(alice, EMISSION_SUPPLY + 1);

    astonicToken.mint(alice, mintAmount);

    vm.expectRevert("AstonicToken: emission supply exceeded");
    astonicToken.mint(alice, EMISSION_SUPPLY - mintAmount + 1);
  }

  /**
   * @dev Tests the mint function's logic for the emission contract.
   * @notice This test checks:
   * 1. Tokens can be successfully minted to specific addresses when called by the emission contract.
   * 2. The emittedAmount state variable correctly reflects the total amount of tokens emitted.
   * 3. It can mint up to emission supply
   */
  function test_mint_whenEmissionSupplyNotExceeded_shouldEmitTokens() public notPaused {
    uint256 mintAmount = 10e18;

    vm.startPrank(emission);
    astonicToken.mint(alice, mintAmount);

    assertEq(astonicToken.balanceOf(alice), mintAmount);
    assertEq(astonicToken.emittedAmount(), mintAmount);

    astonicToken.mint(bob, mintAmount);

    assertEq(astonicToken.balanceOf(bob), mintAmount);
    assertEq(astonicToken.emittedAmount(), 2 * mintAmount);

    astonicToken.mint(alice, EMISSION_SUPPLY - 2 * mintAmount);
    assertEq(astonicToken.emittedAmount(), EMISSION_SUPPLY);
  }

  function test_transfer_whenPaused_shouldRevert() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), alice, amount);

    vm.startPrank(alice);
    vm.expectRevert("AstonicToken: token transfer while paused");
    astonicToken.transfer(bob, amount);
  }

  function test_transferFrom_whenPaused_shouldRevert() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), alice, amount);
    vm.prank(alice);
    astonicToken.approve(bob, amount);

    vm.startPrank(bob);
    vm.expectRevert("AstonicToken: token transfer while paused");
    astonicToken.transferFrom(alice, bob, amount);
  }

  function test_transfer_whenPaused_calledByOwner_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), address(this), amount);
    astonicToken.transfer(bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_transferFrom_whenPaused_calledByOwner_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), alice, amount);
    vm.prank(alice);
    astonicToken.approve(address(this), amount);

    astonicToken.transferFrom(alice, bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_transfer_whenPaused_calledByLocking_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), locking, amount);
    vm.prank(locking);
    astonicToken.transfer(bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_transferFrom_whenPaused_calledByLocking_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), alice, amount);
    vm.prank(alice);
    astonicToken.approve(locking, amount);

    vm.prank(locking);
    astonicToken.transferFrom(alice, bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_transfer_whenPaused_calledByEmission_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), emission, amount);
    vm.prank(emission);
    astonicToken.transfer(bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_transferFrom_whenPaused_calledByEmission_shouldWork() public {
    uint256 amount = 10e18;
    deal(address(astonicToken), alice, amount);
    vm.prank(alice);
    astonicToken.approve(emission, amount);

    vm.prank(emission);
    astonicToken.transferFrom(alice, bob, amount);
    assertEq(astonicToken.balanceOf(bob), amount);
  }

  function test_mint_whenPaused_calledByEmission_shouldWork() public {
    vm.prank(emission);
    astonicToken.mint(emission, 10e18);
    assertEq(astonicToken.balanceOf(emission), 10e18);
  }

  function test_unpause_whenPaused_calledByOwner_shouldUnpause() public {
    astonicToken.unpause();
    assertEq(astonicToken.paused(), false);
  }

  function test_unpause_whenNotPaused_shouldRevert() public notPaused {
    vm.expectRevert("AstonicToken: token is not paused");
    astonicToken.unpause();
  }

  function test_unpause_whenNotCalledByOwner_shouldRevert() public {
    vm.prank(bob);
    vm.expectRevert("Ownable: caller is not the owner");
    astonicToken.unpause();
  }
}
