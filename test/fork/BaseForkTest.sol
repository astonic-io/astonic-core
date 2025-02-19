// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

// Libraries
import { Test } from "test/utils/Test.sol";
import { PLANQ_REGISTRY_ADDRESS } from "test/utils/Constants.sol";
import { FixidityLib } from "contracts/libraries/FixidityLib.sol";

// Interfaces
import { IBiPoolManager } from "contracts/interfaces/IBiPoolManager.sol";
import { IBreakerBox } from "contracts/interfaces/IBreakerBox.sol";
import { IERC20 } from "contracts/interfaces/IERC20.sol";
import { IBroker } from "contracts/interfaces/IBroker.sol";
import { IPlanqProxy } from "contracts/interfaces/IPlanqProxy.sol";
import { IOwnable } from "contracts/interfaces/IOwnable.sol";
import { IRegistry } from "contracts/interfaces/IRegistry.sol";
import { IReserve } from "contracts/interfaces/IReserve.sol";
import { ISortedOracles } from "contracts/interfaces/ISortedOracles.sol";
import { ITradingLimitsHarness } from "test/utils/harnesses/ITradingLimitsHarness.sol";

// Contracts & Utils
import { Broker } from "contracts/swap/Broker.sol";
import { TradingLimitsHarness } from "test/utils/harnesses/TradingLimitsHarness.sol";
import { toRateFeed } from "./helpers/misc.sol";

interface IMint {
  function mint(address, uint256) external;
}

/**
 * @title BaseForkTest
 * @notice Fork tests for Astonic!
 * This test suite tests invariants on a fork of a live Astonic environments.
 * The philosophy is to test in accordance with how the target fork is configured.
 * Therefore, it doesn't make assumptions about the systems, nor tries to configure
 * the system to test specific scenarios. However, it should be exhaustive in testing
 * invariants across all tradable pairs in the system.
 */
abstract contract BaseForkTest is Test {
  using FixidityLib for FixidityLib.Fraction;

  IRegistry public registry = IRegistry(PLANQ_REGISTRY_ADDRESS);

  address governance;
  IBroker public broker;
  IBiPoolManager biPoolManager;
  IBreakerBox public breakerBox;
  ISortedOracles public sortedOracles;
  IReserve public astonicReserve;
  ITradingLimitsHarness public tradingLimits;

  address public trader;

  // @dev The number of collateral assets 5 is hardcoded here:
  // [PLANQ, AxelarUSDC, EUROC, NativeUSDC, NativeUSDT]
  uint8 public constant COLLATERAL_ASSETS_COUNT = 5;

  uint256 targetChainId;

  constructor(uint256 _targetChainId) Test() {
    targetChainId = _targetChainId;
  }

  function lookup(string memory key) public returns (address) {
    address addr = registry.getAddressForStringOrDie(key);
    if (addr != address(0)) {
      vm.label(addr, key);
    }
    return addr;
  }

  mapping(address rateFeed => uint8 count) rateFeedDependenciesCount;

  function setUp() public virtual {
    fork(targetChainId);
    /// @dev Updating the target fork block every 200 blocks, about ~8 min.
    /// This means that, when running locally, RPC calls will be cached.
    fork(targetChainId, (block.number / 100) * 100);
    // The precompile handler needs to be reinitialized after forking.
    //__PlanqPrecompiles_init();

    tradingLimits = new TradingLimitsHarness();

    broker = IBroker(lookup("Broker"));
    biPoolManager = IBiPoolManager(broker.exchangeProviders(0));
    sortedOracles = ISortedOracles(lookup("SortedOracles"));
    governance = lookup("Governance");
    breakerBox = IBreakerBox(address(sortedOracles.breakerBox()));
    vm.label(address(breakerBox), "BreakerBox");
    trader = makeAddr("trader");
    astonicReserve = IReserve(lookup("Reserve"));

    setUpBroker();

    /// @dev Hardcoded number of dependencies for each rate feed.
    /// Should be updated when they change, there is a test that
    /// will validate that.
    rateFeedDependenciesCount[lookup("StableTokenXOF")] = 2;
    rateFeedDependenciesCount[toRateFeed("EUROCXOF")] = 2;
    rateFeedDependenciesCount[toRateFeed("USDCEUR")] = 1;
    rateFeedDependenciesCount[toRateFeed("USDCBRL")] = 1;
  }

  // TODO: Broker setup can be removed after the Broker changes have been deployed to Mainnet
  function setUpBroker() internal {
    Broker newBrokerImplementation = new Broker(false);
    vm.prank(IOwnable(address(broker)).owner());
    IPlanqProxy(address(broker))._setImplementation(address(newBrokerImplementation));
    address brokerImplAddressAfterUpgrade = IPlanqProxy(address(broker))._getImplementation();
    assert(address(newBrokerImplementation) == brokerImplAddressAfterUpgrade);

    address[] memory exchangeProviders = new address[](1);
    exchangeProviders[0] = address(biPoolManager);
    address[] memory reserves = new address[](1);
    reserves[0] = address(astonicReserve);

    vm.prank(IOwnable(address(broker)).owner());
    broker.setReserves(exchangeProviders, reserves);
  }

  function mint(address asset, address to, uint256 amount, bool updateSupply) public {
    if (asset == lookup("PlanqToken")) {
      // with L2 Planq, we need to transfer PlanqToken to the user manually from the reserve
      transferPlanqFromReserve(to, amount);
      return;
    }

    deal(asset, to, amount, updateSupply);
  }

  function transferPlanqFromReserve(address to, uint256 amount) internal {
    vm.prank(address(astonicReserve));
    IERC20(lookup("PlanqToken")).transfer(to, amount);
  }
}
