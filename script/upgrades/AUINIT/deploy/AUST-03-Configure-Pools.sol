// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import { Arrays } from "script/utils/Arrays.sol";
import { Contracts } from "script/utils/Contracts.sol";
import { IRegistry } from "contracts/interfaces/IRegistry.sol";
import { IReserve } from "contracts/interfaces/IReserve.sol";
import { IBiPoolManager } from "contracts/interfaces/IBiPoolManager.sol";
import { IBreakerBox } from "contracts/interfaces/IBreakerBox.sol";
import { FixidityLib } from "contracts/libraries/FixidityLib.sol";
import { IBroker } from "contracts/interfaces/IBroker.sol";
import { IPricingModule } from "contracts/interfaces/IPricingModule.sol";
import { IERC20Metadata } from "contracts/interfaces/IERC20Metadata.sol";
import { IStableTokenV2 } from "contracts/interfaces/IStableTokenV2.sol";
import { IMedianDeltaBreaker } from "contracts/interfaces/IMedianDeltaBreaker.sol";
import { IValueDeltaBreaker } from "contracts/interfaces/IValueDeltaBreaker.sol";
import { IProxy } from "contracts/interfaces/IProxy.sol";
import { ITradingLimits } from "contracts/interfaces/ITradingLimits.sol";
import { ISortedOracles } from "contracts/interfaces/ISortedOracles.sol";
import { PlanqChain } from "script/utils/Chain.sol";
import { Script } from "script/utils/Script.sol";
import { console2 } from "forge-std/Script.sol";
import {Config} from "script/utils/Config.sol";

contract AUST03_CreateContracts is Script {
    using Contracts for Contracts.Cache;
    using FixidityLib for FixidityLib.Fraction;

    IRegistry private registry = IRegistry(0x9DabFe01de024C681320eb80FBc64EccEaa58ca2);
    uint256 medianDeltaBreakerCooldown = 0;
    uint256 medianDeltaBreakerThreshold = 0;

    uint256 valueDeltaBreakerCooldown = 0;
    uint256 valueDeltaBreakerThreshold = 0;

    address sortedOracles = registry.getAddressForString("SortedOracles");

    address[] __rateFeedIDs = new address[](0);
    uint256[] __rateChangeThresholds = new uint256[](0);
    uint256[] __cooldowns = new uint256[](0);

    function run() public {
        address biPoolManagerProxy = address(0x6257f6315Ae36eB88AdD2eB4F886a0A4261Ae1B1);
        address brokerProxy = address(0xaD7e1F70f4C9cdbe41516188433dc3Da9A7d1187);
        address csPricingModule = address(0xb617E4D55c5da46c0BA3Dc3b169F2ce0dDbd829A);
        address cpPricingModule = address(0xe3b595bD30264D1895fA6114Bb0321Ede163DF5e);
        address breakerBox = address(0x26039b9a3d73184f212f8A4622230a953EE9e51E);
        address biPoolManager = address(0xAa74B934372F770B0975617Bdc5E1CE82eFC84Ad);
        address broker = address(0xb822599237cd7536439523Ae660Dd163De97fC74);
        address medianDeltaBreaker = address(0x7C2e9Cae119a626036ea7A7A685C9F06BAF65a7B);
        address valueDeltaBreaker = address(0xE0f746b2bb523164f3Ae4f88Ed687B78761A4d6A);

        vm.startBroadcast(PlanqChain.deployerPrivateKey());
        {

            Config.Pool[] memory allPoolConfig = new Config.Pool[](6);
            allPoolConfig[0] = aUSDPlanq_PoolConfig();
            allPoolConfig[1] = aEURPlanq_PoolConfig();
            allPoolConfig[2] = aBRLPlanq_PoolConfig();
            allPoolConfig[3] = aUSDUSDC_PoolConfig();
            allPoolConfig[4] = aEURUSDC_PoolConfig();
            allPoolConfig[5] = aBRLUSDC_PoolConfig();

            IPricingModule constantProduct = IPricingModule(cpPricingModule);
            IPricingModule constantSum = IPricingModule(csPricingModule);


            for (uint256 i = 0; i < allPoolConfig.length; i++) {
                Config.Pool memory poolConfig = allPoolConfig[i];

                IBiPoolManager.PoolExchange memory pool = IBiPoolManager.PoolExchange({
                    asset0: poolConfig.asset0,
                    asset1: poolConfig.asset1,
                    pricingModule: poolConfig.isConstantSum ? constantSum : constantProduct,
                    bucket0: 0,
                    bucket1: 0,
                    lastBucketUpdate: 0,
                    config: IBiPoolManager.PoolConfig(
                        FixidityLib.wrap(poolConfig.spread.unwrap()),
                        poolConfig.referenceRateFeedID,
                        poolConfig.referenceRateResetFrequency,
                        poolConfig.minimumReports,
                        poolConfig.stablePoolResetSize
                        )
                    });
                IBiPoolManager(biPoolManagerProxy).createExchange(pool);
            }


            Config.RateFeed[] memory rateFeedConfig = new Config.RateFeed[](6);
            rateFeedConfig[0] = PLQUSD_RateFeedConfig();
            rateFeedConfig[1] = PLQEUR_RateFeedConfig();
            rateFeedConfig[2] = PLQBRL_RateFeedConfig();
            rateFeedConfig[3] = USDCUSD_RateFeedConfig();
            rateFeedConfig[4] = USDCEUR_RateFeedConfig();
            rateFeedConfig[5] = USDCBRL_RateFeedConfig();


            IMedianDeltaBreaker(medianDeltaBreaker).setCooldownTime(
            Arrays.addresses(
                rateFeedConfig[0].rateFeedID,
                rateFeedConfig[1].rateFeedID,
                rateFeedConfig[2].rateFeedID
                ),
                rateFeedConfig[0].medianDeltaBreaker0.cooldown
            );

            IMedianDeltaBreaker(medianDeltaBreaker).setCooldownTime(
            Arrays.addresses(
                rateFeedConfig[3].rateFeedID
                ),
                rateFeedConfig[3].valueDeltaBreaker0.cooldown
            );

            IMedianDeltaBreaker(medianDeltaBreaker).setCooldownTime(
            Arrays.addresses(
                rateFeedConfig[4].rateFeedID,
                rateFeedConfig[5].rateFeedID
                ),
                rateFeedConfig[4].medianDeltaBreaker0.cooldown
            );

            IMedianDeltaBreaker(medianDeltaBreaker).setRateChangeThresholds(
            Arrays.addresses(
                rateFeedConfig[0].rateFeedID,
                rateFeedConfig[1].rateFeedID,
                rateFeedConfig[2].rateFeedID,
                rateFeedConfig[3].rateFeedID,
                rateFeedConfig[4].rateFeedID,
                rateFeedConfig[5].rateFeedID
                ),
            Arrays.uints(
                rateFeedConfig[0].medianDeltaBreaker0.threshold.unwrap(),
                rateFeedConfig[1].medianDeltaBreaker0.threshold.unwrap(),
                rateFeedConfig[2].medianDeltaBreaker0.threshold.unwrap(),
                rateFeedConfig[3].valueDeltaBreaker0.threshold.unwrap(),
                rateFeedConfig[4].medianDeltaBreaker0.threshold.unwrap(),
                rateFeedConfig[5].medianDeltaBreaker0.threshold.unwrap()
                )
            );

            IValueDeltaBreaker(valueDeltaBreaker).setReferenceValues(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.referenceValue)
            );

            IValueDeltaBreaker(valueDeltaBreaker).setCooldownTimes(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.cooldown)
            );

            IValueDeltaBreaker(valueDeltaBreaker).setRateChangeThresholds(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.threshold.unwrap())
            );

            for (uint256 i = 0; i < rateFeedConfig.length; i++) {

                if (rateFeedConfig[i].medianDeltaBreaker0.enabled) {
                    IBreakerBox(breakerBox).toggleBreaker(medianDeltaBreaker, rateFeedConfig[i].rateFeedID, true);
                }
                if (rateFeedConfig[i].valueDeltaBreaker0.enabled) {
                    IBreakerBox(breakerBox).toggleBreaker(valueDeltaBreaker, rateFeedConfig[i].rateFeedID, true);
                }
            }

            ISortedOracles(sortedOracles).setBreakerBox(IBreakerBox(breakerBox));

            for (uint256 i = 0; i < allPoolConfig.length; i++) {
                Config.Pool memory poolConfig = allPoolConfig[i];
                IBroker(brokerProxy).configureTradingLimit(
                    getExchangeId(poolConfig.asset0,poolConfig.asset1, poolConfig.isConstantSum),
                    poolConfig.asset0,
                    ITradingLimits.Config({
                        timestep0: poolConfig.asset0limits.timeStep0,
                        limit0: poolConfig.asset0limits.limit0,
                        timestep1: poolConfig.asset0limits.timeStep1,
                        limit1: poolConfig.asset0limits.limit1,
                        limitGlobal: poolConfig.asset0limits.limitGlobal,
                        flags: Config.tradingLimitConfigToFlag(poolConfig.asset0limits)
                })
                );
            }

        }
        vm.stopBroadcast();

    }

    /**
 * @notice Helper function to get the exchange ID for a pool.
   */
    function getExchangeId(address asset0, address asset1, bool isConstantSum) internal view returns (bytes32) {
        return
            keccak256(
            abi.encodePacked(
                IERC20Metadata(asset0).symbol(),
                IERC20Metadata(asset1).symbol(),
                isConstantSum ? "ConstantSum" : "ConstantProduct"
            )
        );
    }


    function aUSDPlanq_PoolConfig() internal view returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableToken"),
            asset1: registry.getAddressForString("PlanqToken"),
            isConstantSum: false,
            spread: FixidityLib.newFixedFraction(25, 10000), // 0.0025
            referenceRateResetFrequency: 5 minutes,
            minimumReports: 2,
            stablePoolResetSize: 7_200_000 * 1e18, // 7.2 million
            referenceRateFeedID: 0x8c86e877e9632cD18a66E8A787f93FB3DE56446c,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 10_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 50_000,
            enabledGlobal: false,
            limitGlobal: 0
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });

    }

    function PLQUSD_RateFeedConfig(
    ) internal view returns (Config.RateFeed memory config) {
        config.rateFeedID = 0x8c86e877e9632cD18a66E8A787f93FB3DE56446c;
        config.medianDeltaBreaker0 = Config.MedianDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(3, 100), // 0.03
            cooldown: 30 minutes,
            smoothingFactor: 0
        });
    }

    function aEURPlanq_PoolConfig() internal view returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableTokenEUR"),
            asset1: registry.getAddressForString("PlanqToken"),
            isConstantSum: false,
            spread: FixidityLib.newFixedFraction(25, 10000), // 0.0025
            referenceRateResetFrequency: 5 minutes,
            minimumReports: 2,
            stablePoolResetSize: 1_800_000 * 1e18, // 1.8 million
            referenceRateFeedID: 0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 10_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 50_000,
            enabledGlobal: false,
            limitGlobal: 0
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });

    }

    function PLQEUR_RateFeedConfig(
    ) internal view returns (Config.RateFeed memory config) {
        config.rateFeedID = 0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5;
        config.medianDeltaBreaker0 = Config.MedianDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(3, 100), // 0.03
            cooldown: 30 minutes,
            smoothingFactor: 0
        });
    }

    function aBRLPlanq_PoolConfig() internal view returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableTokenBRL"),
            asset1: registry.getAddressForString("PlanqToken"),
            isConstantSum: false,
            spread: FixidityLib.newFixedFraction(25, 10000), // 0.0025
            referenceRateResetFrequency: 5 minutes,
            minimumReports: 2,
            stablePoolResetSize: 3_000_000 * 1e18, // 3 million
            referenceRateFeedID: 0x5bb8157db521739C3294433B6cD71A46630320fd,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 10_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 50_000,
            enabledGlobal: false,
            limitGlobal: 0
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });

    }

    function PLQBRL_RateFeedConfig(
    ) internal view returns (Config.RateFeed memory config) {
        config.rateFeedID = 0x5bb8157db521739C3294433B6cD71A46630320fd;
        config.medianDeltaBreaker0 = Config.MedianDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(3, 100), // 0.03
            cooldown: 30 minutes,
            smoothingFactor: 0
        });
    }

    function aUSDUSDC_PoolConfig() internal returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableToken"),
            asset1: registry.getAddressForString("BridgedUSDC"),
            isConstantSum: true,
            spread: FixidityLib.newFixedFraction(2, 10000), // 0.0002
            minimumReports: 2,
            stablePoolResetSize: 12_000_000 * 1e18, // 12 million
            referenceRateResetFrequency: 5 minutes,
            referenceRateFeedID: 0xA1A8003936862E7a15092A91898D69fa8bCE290c,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 50_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 100_000,
            enabledGlobal: false,
            limitGlobal: 0
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });
    }

    function USDCUSD_RateFeedConfig() internal returns (Config.RateFeed memory config) {
        config.rateFeedID = 0xA1A8003936862E7a15092A91898D69fa8bCE290c;
        config.valueDeltaBreaker0 = Config.ValueDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(5, 1000), // 0.005
            referenceValue: 1e24, // 1$ numerator for 1e24 denominator
            cooldown: 1 seconds
        });
    }

    function aEURUSDC_PoolConfig() internal returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableTokenEUR"),
            asset1: registry.getAddressForString("BridgedUSDC"),
            isConstantSum: true,
            spread: FixidityLib.newFixedFraction(25, 10000), // 0.0025
            minimumReports: 2,
            stablePoolResetSize: 1_800_000 * 1e18, // 1.8 million
            referenceRateResetFrequency: 5 minutes,
            referenceRateFeedID: 0x206B25Ea01E188Ee243131aFdE526bA6E131a016,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 10_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 50_000,
            enabledGlobal: true,
            limitGlobal: 5_000_000
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });
    }

    function USDCEUR_RateFeedConfig() internal returns (Config.RateFeed memory config) {
        config.rateFeedID = 0x206B25Ea01E188Ee243131aFdE526bA6E131a016;
        config.medianDeltaBreaker0 = Config.MedianDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(2, 100), // 0.02
            cooldown: 15 minutes,
            smoothingFactor: FixidityLib.newFixedFraction(5, 10000).unwrap()
        });
        config.dependentRateFeeds = Arrays.addresses(0x206B25Ea01E188Ee243131aFdE526bA6E131a016);
    }

    function aBRLUSDC_PoolConfig() internal returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: registry.getAddressForString("StableTokenBRL"),
            asset1: registry.getAddressForString("BridgedUSDC"),
            isConstantSum: true,
            spread: FixidityLib.newFixedFraction(25, 10000), // 0.0025
            minimumReports: 2,
            stablePoolResetSize: 1_800_000 * 1e18, // 1.8 million
            referenceRateResetFrequency: 5 minutes,
            referenceRateFeedID: 0x25F21A1f97607Edf6852339fad709728cffb9a9d,
            asset0limits: Config.TradingLimit({
            enabled0: true,
            timeStep0: 5 minutes,
            limit0: 10_000,
            enabled1: true,
            timeStep1: 1 days,
            limit1: 50_000,
            enabledGlobal: true,
            limitGlobal: 2_000_000
        }),
            asset1limits: Config.emptyTradingLimitConfig()
        });
    }

    function USDCBRL_RateFeedConfig() internal returns (Config.RateFeed memory config) {
        config.rateFeedID = 0x25F21A1f97607Edf6852339fad709728cffb9a9d;
        config.medianDeltaBreaker0 = Config.MedianDeltaBreaker({
            enabled: true,
            threshold: FixidityLib.newFixedFraction(25, 1000), // 0.025
            cooldown: 15 minutes,
            smoothingFactor: FixidityLib.newFixedFraction(5, 10000).unwrap()
        });
        config.dependentRateFeeds = Arrays.addresses(0x25F21A1f97607Edf6852339fad709728cffb9a9d);
    }

}
