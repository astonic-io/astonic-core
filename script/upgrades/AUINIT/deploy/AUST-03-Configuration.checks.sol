// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

import "../../../../contracts/interfaces/IBreakerBox.sol";
import { Arrays } from "script/utils/Arrays.sol";
import { Contracts } from "script/utils/Contracts.sol";
import { FixidityLib } from "contracts/libraries/FixidityLib.sol";
import { IBiPoolManager } from "contracts/interfaces/IBiPoolManager.sol";
import { IBreakerBox } from "contracts/interfaces/IBreakerBox.sol";
import { Broker } from "contracts/swap/Broker.sol";
import { IERC20Metadata } from "contracts/interfaces/IERC20Metadata.sol";
import { IMedianDeltaBreaker } from "contracts/interfaces/IMedianDeltaBreaker.sol";
import { IPricingModule } from "contracts/interfaces/IPricingModule.sol";
import { IProxy } from "contracts/interfaces/IProxy.sol";
import { IRegistry } from "contracts/interfaces/IRegistry.sol";
import { IReserve } from "contracts/interfaces/IReserve.sol";
import { ISortedOracles } from "contracts/interfaces/ISortedOracles.sol";
import { IStableTokenV2 } from "contracts/interfaces/IStableTokenV2.sol";
import { ITradingLimits } from "contracts/interfaces/ITradingLimits.sol";
import { IValueDeltaBreaker } from "contracts/interfaces/IValueDeltaBreaker.sol";
import { MockERC20 } from "script/utils/MockErc20.sol";
import { PlanqChain } from "script/utils/Chain.sol";
import { Script } from "script/utils/Script.sol";
import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/Script.sol";
import {TradingLimits} from "contracts/libraries/TradingLimits.sol";


/**
 * @title IBrokerWithCasts
 * @notice Interface for Broker with tuple -> struct casting
 * @dev This is used to access the internal trading limits state and
 * config as structs as opposed to tuples.
 */
interface IBrokerWithCasts {
    function tradingLimitsConfig(bytes32 id) external view returns (ITradingLimits.Config memory);
}

interface WPLQ {
    function approve(address spender, uint256 amount) external returns (bool);
    function deposit() payable external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function withdraw() external;
}

contract AUST03Checks is Script, Test {
    using TradingLimits for ITradingLimits.Config;

    Broker private broker;
    IBreakerBox private breakerBox;
    IReserve public reserve;
    IRegistry private registry = IRegistry(0x9DabFe01de024C681320eb80FBc64EccEaa58ca2);

    address public planqToken;
    address public aUSD;
    address public aEUR;
    address public aBRL;
    address public bridgedUSDC;

    function setUp() public {
        // Load addresses from deployments

        // Get proxy addresses of the deployed tokens
        aUSD = registry.getAddressForString("StableToken");
        aEUR = registry.getAddressForString("StableTokenEUR");
        aBRL = registry.getAddressForString("StableTokenBRL");

        bridgedUSDC = 0xecEEEfCEE421D8062EF8d6b4D814efe4dc898265;
        planqToken = registry.getAddressForString("PlanqToken");
        broker = Broker(registry.getAddressForString("Broker"));
        breakerBox = IBreakerBox(registry.getAddressForString("BreakerBox"));
        reserve = IReserve(0xBc51eCE1F7c7C0c351d413e8162bBA6C9e28A9f6);
    }

    function run() public {
        setUp();
        vm.deal(address(this), 10000000e20);
        WPLQ(planqToken).deposit{value: 1e20}();

        verifyPartialReserve();
        verifyBroker();

        doSwaps();
    }

    /* ================================================================ */
    /* =================== Partial Reserve checks ===================== */
    /* ================================================================ */

    function verifyPartialReserve() public {
        console2.log("\n== Verifying partial reserve... ==");

        checkReserveCollateralAssets();
        checkReserveStableAssets();
        checkReserveSpenders();
        //checkReserveMultisigCanSpend();
    }

    function checkReserveCollateralAssets() public view {
        require(reserve.checkIsCollateralAsset(planqToken), "PLQ is not collateral asset");
        require(reserve.checkIsCollateralAsset(bridgedUSDC), "bridgedUSDC is not collateral asset");

        console2.log("collateral assets are added");
    }

    function checkReserveStableAssets() public view {
        require(reserve.isStableAsset(aUSD), "aUSD is not a stable asset");
        require(reserve.isStableAsset(aEUR), "aEUR is not a stable asset");
        require(reserve.isStableAsset(aBRL), "aBRL is not a stable asset!!");

        console2.log("stable assets are added");
    }

    function checkReserveSpenders() public {
        require(reserve.isExchangeSpender(address(broker)), "Broker is not an exchange spender");

        address spenderMultiSig = 0x268C754bb4Ee50dCa0aF1E81e6B3eDA3c8Be93db;
        require(reserve.isSpender(spenderMultiSig), "Astonic multisig is not a spender");

        console2.log("spender addresses are added");
    }

    /*function checkReserveMultisigCanSpend() public {
        uint256 oneMillion = 1_000_000 * 1e18;

        vm.deal(address(reserve), oneMillion);
        deal(bridgedUSDC, address(reserve), oneMillion, true);

        address payable mainReserve = payable(address(uint160(registry.getAddressForString("Reserve"))));
        uint256 prevMainReservePlanqBalance = address(mainReserve).balance;
        uint256 prevMainReserveUsdcBalance = MockERC20(bridgedUSDC).balanceOf(address(mainReserve));

        address multiSigAddr = 0x268C754bb4Ee50dCa0aF1E81e6B3eDA3c8Be93db;
        vm.startPrank(multiSigAddr);
        reserve.transferCollateralAsset(planqToken, mainReserve, oneMillion);
        reserve.transferCollateralAsset(bridgedUSDC, mainReserve, oneMillion);
        vm.stopPrank();

        assert(address(mainReserve).balance == prevMainReservePlanqBalance + oneMillion);
        assert(MockERC20(bridgedUSDC).balanceOf(address(mainReserve)) == prevMainReserveUsdcBalance + oneMillion);

        console2.log("multiSig spender can spend collateral assets");
    }*/

    /* ================================================================ */
    /* ========================= Broker checks ======================== */
    /* ================================================================ */

    function verifyBroker() public view {
        console2.log("\n== Verifying broker... ==");

        verifyExchangeProviders();
        verifyBiPoolManager();
        verifyExchanges();
        verifyTradingLimits();
    }

    function verifyExchangeProviders() public view {
        address[] memory exchangeProviders = broker.getExchangeProviders();
        if (exchangeProviders.length != 1) {
            console2.log("Exchange provider count was %s but should have been 1", exchangeProviders.length);
            revert("Exchange provider count was not 1");
        }
        console2.log("checked exchange providers");
    }

    function verifyBiPoolManager() public view {
        address[] memory exchangeProviders = broker.getExchangeProviders();
        address biPoolManager = exchangeProviders[0];

        // Get the address of the deployed BiPoolManagerProxy from the deployment json.
        address expectedBiPoolManager = 0x6257f6315Ae36eB88AdD2eB4F886a0A4261Ae1B1;
        if (biPoolManager != expectedBiPoolManager) {
            console2.log(
                "The address of the BiPool manager retrieved from the Broker was not the address found in the deployment json."
            );
            console2.log("Expected address:", expectedBiPoolManager);
            console2.log("Actual address:", biPoolManager);

            revert("BiPoolManager address found was not expected. See logs.");
        }
        console2.log("checked biPoolManager address");
    }

    function verifyExchanges() public view {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32[] memory exchanges = bpm.getExchangeIds();

        for (uint256 i = 0; i < exchanges.length; i++) {
            bytes32 exchangeId = exchanges[i];
            IBiPoolManager.PoolExchange memory pool = bpm.getPoolExchange(exchangeId);

            require(
                pool.asset0 == aUSD || pool.asset0 == aEUR || pool.asset0 == aBRL,
                "asset0 is not a stable asset in the exchange"
            );
            require(
                pool.asset1 == planqToken || pool.asset1 == bridgedUSDC,
                "asset1 is not PLQ or bridgedUSDC in the exchange"
            );
        }

        console2.log("exchanges correctly configured");
    }

    function verifyTradingLimits() public view {
        IBrokerWithCasts _broker = IBrokerWithCasts(address(broker));
        IBiPoolManager bpm = getBiPoolManager();
        bytes32[] memory exchanges = bpm.getExchangeIds();

        for (uint256 i = 0; i < exchanges.length; i++) {
            bytes32 exchangeId = exchanges[i];
            IBiPoolManager.PoolExchange memory pool = bpm.getPoolExchange(exchangeId);
            bytes32 limitId = exchangeId ^ bytes32(uint256(uint160(pool.asset0)));
            ITradingLimits.Config memory limits = _broker.tradingLimitsConfig(limitId);

            if (limits.timestep0 == 0 || limits.timestep1 == 0 || limits.limit0 == 0 || limits.limit1 == 0) {
                console2.log("The trading limit for %s, %s was not set", pool.asset0, pool.asset1);
                revert("Not all trading limits were set.");
            }
        }

        console2.log("Trading limits set for all exchanges");
    }

    function verifyCircuitBreaker() public view {
        address[] memory rateFeeds = breakerBox.getRateFeeds();
        address[] memory breakers = breakerBox.getBreakers();
        for (uint256 i = 0; i < rateFeeds.length; i++) {
            address token = rateFeeds[i];
            IBreakerBox.BreakerStatus memory status = breakerBox.rateFeedBreakerStatus(token, breakers[i]);

            // if configured, TradingModeInfo.lastUpdatedTime is greater than zero
            if (status.lastUpdatedTime == 0) {
                console2.log("Circuit breaker for %s was not set", token);
                revert("Not all breakers were set.");
            }
        }

        console2.log("Circuit breakers set for all tokens");
    }

    /* ================================================================ */
    /* ============================= Swaps =========================== */
    /* ================================================================ */

    function doSwaps() public {
        console2.log("\n== Doing some test swaps... ==");
        swapPlanqToaUSD();
        swapPlanqToaEUR();
        swapPlanqToaBRL();
        swapBridgedUSDCToaUSD();
        swapBridgedUSDCToaEUR();
        swapBridgedUSDCToaBRL();
        swapaUSDtoBridgedUSDC();
        swapaEURtoBridgedUSDC();
        swapaBRLtoBridgedUSDC();
    }

    function swapPlanqToaUSD() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(0);

        address tokenIn = planqToken;
        address tokenOut = aUSD;

        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, 1e18);

        IERC20Metadata(registry.getAddressForString("PlanqToken")).approve(address(broker), 1e18);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, 1e18, amountOut - 1e10);

        console2.log("PLQ -> aUSD swap successful");
    }

    function swapPlanqToaEUR() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(1);

        address tokenIn = planqToken;
        address tokenOut = aEUR;

        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, 1e18);

        IERC20Metadata(registry.getAddressForString("PlanqToken")).approve(address(broker), 1e18);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, 1e18, amountOut - 1e10);

        console2.log("PLQ -> aEUR swap successful");
    }

    function swapPlanqToaBRL() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(2);

        address tokenIn = planqToken;
        address tokenOut = aBRL;

        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, 1e18);

        IERC20Metadata(registry.getAddressForString("PlanqToken")).approve(address(broker), 1e18);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, 1e18, amountOut - 1e10);

        console2.log("PLQ -> aBRL swap successful");
    }

    function swapBridgedUSDCToaUSD() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(3);

        address trader = vm.addr(1);
        address tokenIn = bridgedUSDC;
        address tokenOut = aUSD;
        uint256 amountIn = 100e6;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);

        assert(mockBridgedUSDCContract.balanceOf(trader) == 0);
        deal(bridgedUSDC, trader, amountIn, true);
        assert(mockBridgedUSDCContract.balanceOf(trader) == amountIn);

        vm.startPrank(trader);
        uint256 beforeaUSD = MockERC20(aUSD).balanceOf(trader);
        mockBridgedUSDCContract.approve(address(broker), amountIn);

        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);

        assert(mockBridgedUSDCContract.balanceOf(trader) == 0);
        assert(MockERC20(aUSD).balanceOf(trader) == beforeaUSD + amountOut);
        vm.stopPrank();

        console2.log("bridgedUSDC -> aUSD swap successful");
    }

    function swapBridgedUSDCToaEUR() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(4);

        address trader = vm.addr(1);
        address tokenIn = bridgedUSDC;
        address tokenOut = aEUR;
        uint256 amountIn = 100e6;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);

        deal(bridgedUSDC, trader, amountIn, true);

        vm.startPrank(trader);
        uint256 beforeaUSD = MockERC20(aEUR).balanceOf(trader);
        mockBridgedUSDCContract.approve(address(broker), amountIn);

        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);

        assert(MockERC20(aEUR).balanceOf(trader) == beforeaUSD + amountOut);
        vm.stopPrank();

        console2.log("bridgedUSDC -> aEUR swap successful");
    }

    function swapBridgedUSDCToaBRL() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(5);

        address trader = vm.addr(1);
        address tokenIn = bridgedUSDC;
        address tokenOut = aBRL;
        uint256 amountIn = 100e6;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);

        deal(bridgedUSDC, trader, amountIn, true);

        vm.startPrank(trader);
        uint256 beforeaUSD = MockERC20(aBRL).balanceOf(trader);
        mockBridgedUSDCContract.approve(address(broker), amountIn);

        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);

        assert(MockERC20(aBRL).balanceOf(trader) == beforeaUSD + amountOut);
        vm.stopPrank();

        console2.log("bridgedUSDC -> aBRL swap successful");
    }

    function swapaUSDtoBridgedUSDC() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(3);

        address trader = vm.addr(1);
        address tokenIn = aUSD;
        address tokenOut = bridgedUSDC;
        uint256 amountIn = 10e18;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        // fund reserve with usdc
        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);
        deal(bridgedUSDC, address(reserve), 1000e18, true);

        vm.startPrank(trader);
        MockERC20(aUSD).approve(address(broker), amountIn);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);
        vm.stopPrank();

        console2.log("aUSD -> bridgedUSDC swap successful");
    }

    function swapaEURtoBridgedUSDC() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(4);

        address trader = vm.addr(1);
        address tokenIn = aEUR;
        address tokenOut = bridgedUSDC;
        uint256 amountIn = 10e18;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        // fund reserve with usdc
        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);
        deal(bridgedUSDC, address(reserve), 1000e18, true);

        vm.startPrank(trader);
        MockERC20(aEUR).approve(address(broker), amountIn);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);
        vm.stopPrank();

        console2.log("aEUR -> bridgedUSDC swap successful");
    }

    function swapaBRLtoBridgedUSDC() public {
        IBiPoolManager bpm = getBiPoolManager();
        bytes32 exchangeID = bpm.exchangeIds(5);

        address trader = vm.addr(1);
        address tokenIn = aBRL;
        address tokenOut = bridgedUSDC;
        uint256 amountIn = 10e18;
        uint256 amountOut = broker.getAmountOut(address(bpm), exchangeID, tokenIn, tokenOut, amountIn);

        // fund reserve with usdc
        MockERC20 mockBridgedUSDCContract = MockERC20(bridgedUSDC);
        deal(bridgedUSDC, address(reserve), 1000e18, true);

        vm.startPrank(trader);
        MockERC20(aBRL).approve(address(broker), amountIn);
        broker.swapIn(address(bpm), exchangeID, tokenIn, tokenOut, amountIn, amountOut);
        vm.stopPrank();

        console2.log("aBRL -> bridgedUSDC swap successful");
    }

    /* ================================================================ */
    /* ============================ Helpers =========================== */
    /* ================================================================ */

    function getBiPoolManager() public view returns (IBiPoolManager) {
        return IBiPoolManager(broker.getExchangeProviders()[0]);
    }
}
