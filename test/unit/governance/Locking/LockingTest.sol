// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable func-name-mixedcase, contract-name-camelcase

import { GovernanceTest } from "../GovernanceTest.sol";
import { LockingHarness } from "test/utils/harnesses/LockingHarness.sol";
import { MockAstonicToken } from "test/utils/mocks/MockAstonicToken.sol";
import { IERC20Upgradeable } from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

contract LockingTest is GovernanceTest {
  LockingHarness public locking;
  MockAstonicToken public astonicToken;

  uint32 public weekInBlocks;

  function setUp() public virtual {
    astonicToken = new MockAstonicToken();
    locking = new LockingHarness();

    vm.prank(owner);
    locking.__Locking_init(IERC20Upgradeable(address(astonicToken)), 0, 0, 0);

    weekInBlocks = uint32(locking.WEEK());

    vm.prank(alice);
    astonicToken.approve(address(locking), type(uint256).max);

    _incrementBlock(2 * weekInBlocks);
  }

  function _incrementBlock(uint32 _amount) internal {
    locking.incrementBlock(_amount);
  }

  function _reduceBlock(uint32 _amount) internal {
    locking.reduceBlock(_amount);
  }
}
