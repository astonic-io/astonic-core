// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.13;

import "../../../utils/Config.sol";
import { Arrays } from "script/utils/Arrays.sol";
import { BiPoolManager } from "contracts/swap/BiPoolManager.sol";
import { BiPoolManagerProxy } from "contracts/swap/BiPoolManagerProxy.sol";
import { BreakerBox } from "contracts/oracles/BreakerBox.sol";
import { BreakerBoxProxy } from "contracts/oracles/BreakerBoxProxy.sol";
import { Broker } from "contracts/swap/Broker.sol";
import { BrokerProxy } from "contracts/swap/BrokerProxy.sol";
import { ConstantProductPricingModule } from "contracts/swap/ConstantProductPricingModule.sol";
import { ConstantSumPricingModule } from "contracts/swap/ConstantSumPricingModule.sol";
import { Contracts } from "script/utils/Contracts.sol";
import { IRegistry } from "contracts/interfaces/IRegistry.sol";
import { ISortedOracles } from "contracts/interfaces/ISortedOracles.sol";
import { MedianDeltaBreaker } from "contracts/oracles/breakers/MedianDeltaBreaker.sol";
import { PlanqChain } from "script/utils/Chain.sol";
import { Reserve } from "contracts/swap/Reserve.sol";
import { ReserveProxy } from "contracts/swap/ReserveProxy.sol";
import { Script } from "script/utils/Script.sol";
import { StableTokenBRLProxy } from "contracts/tokens/StableTokenBRLProxy.sol";
import { StableTokenEURProxy } from "contracts/tokens/StableTokenEURProxy.sol";
import { StableTokenProxy } from "contracts/tokens/StableTokenProxy.sol";
import { StableTokenV2 } from "contracts/tokens/StableTokenV2.sol";
import { ValueDeltaBreaker } from "contracts/oracles/breakers/ValueDeltaBreaker.sol";
import { console2 } from "forge-std/Script.sol";


contract AUST03_CreateContracts is Script {
    using Contracts for Contracts.Cache;
    using TradingLimits for TradingLimits.Config;

    Contracts.Cache public contracts;
    ConstantSumPricingModule private csPricingModule;
    ConstantProductPricingModule private cpPricingModule;
    MedianDeltaBreaker private medianDeltaBreaker;
    ValueDeltaBreaker private valueDeltaBreaker;
    IRegistry private registry = IRegistry(0x9DabFe01de024C681320eb80FBc64EccEaa58ca2);
    uint256 medianDeltaBreakerCooldown = 0;
    uint256 medianDeltaBreakerThreshold = 0;

    uint256 valueDeltaBreakerCooldown = 0;
    uint256 valueDeltaBreakerThreshold = 0;

    address sortedOracles = contracts.planqRegistry("SortedOracles");

    address[] memory __rateFeedIDs = new address[](0);
    uint256[] memory __rateChangeThresholds = new uint256[](0);
    uint256[] memory __cooldowns = new uint256[](0);

    function run() public {
        address breakerBoxProxy;
        address biPoolManagerProxy;
        address brokerProxy;
        address reserveProxy;
        address stableTokenProxy;
        address stableTokenEURProxy;
        address stableTokenBRLProxy;

        address stableToken;
        address breakerBox;
        address biPoolManager;
        address broker;
        address reserve;

        vm.startBroadcast(Chain.deployerPrivateKey());
        {
            // Proxies
            breakerBoxProxy = address(new BreakerBoxProxy());
            biPoolManagerProxy = address(new BiPoolManagerProxy());
            brokerProxy = address(new BrokerProxy());
            reserveProxy = address(new ReserveProxy());
            stableTokenProxy = address(new StableTokenProxy());
            stableTokenEURProxy = address(new StableTokenEURProxy());
            stableTokenBRLProxy = address(new StableTokenBRLProxy());

            registry.setAddressFor("StableToken", stableTokenProxy);
            registry.setAddressFor("StableTokenEUR", stableTokenEURProxy);
            registry.setAddressFor("StableTokenBRL", stableTokenBRLProxy);
            registry.setAddressFor("Reserve", reserveProxy);
            registry.setAddressFor("Broker", brokerProxy);
            registry.setAddressFor("BridgedUSDC", address(0xecEEEfCEE421D8062EF8d6b4D814efe4dc898265));

            //"PLQUSDRateFeedAddr": "0x8c86e877e9632cD18a66E8A787f93FB3DE56446c",
            //"PLQEURRateFeedAddr": "0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5",
            //"PLQBRLRateFeedAddr": "0x5bb8157db521739C3294433B6cD71A46630320fd",
            //"USDCUSDRateFeedAddr": "0xA1A8003936862E7a15092A91898D69fa8bCE290c",
            //"USDCEURRateFeedAddr": "0x206B25Ea01E188Ee243131aFdE526bA6E131a016",
            //"USDCBRLRateFeedAddr": "0x25F21A1f97607Edf6852339fad709728cffb9a9d",

            // Implementations
            csPricingModule = new ConstantSumPricingModule();
            cpPricingModule = new ConstantProductPricingModule();
            stableToken = address(new StableTokenV2(true));
            breakerBox = address(new BreakerBox(__rateFeedIDs, ISortedOracles(sortedOracles)));
            biPoolManager = address(new BiPoolManager(false));
            broker = address(new Broker(false));
            reserve = address(new Reserve(false));

            medianDeltaBreaker = new MedianDeltaBreaker(
                medianDeltaBreakerCooldown,
                medianDeltaBreakerThreshold,
                ISortedOracles(sortedOracles),
                breakerBox,
                __rateFeedIDs,
                __rateChangeThresholds,
                __cooldowns
            );

            valueDeltaBreaker = new ValueDeltaBreaker(
                valueDeltaBreakerCooldown,
                valueDeltaBreakerThreshold,
                ISortedOracles(sortedOracles),
                __rateFeedIDs,
                __rateChangeThresholds,
                __cooldowns
            );

            BreakerBoxProxy(breakerBoxProxy)._setAndInitializeImplementation(
                breakerBox,
                abi.encodeWithSelector(
                    BreakerBox(0).initialize.selector,
                    Arrays.addresses(
                        0x8c86e877e9632cD18a66E8A787f93FB3DE56446c,
                        0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5,
                        0x5bb8157db521739C3294433B6cD71A46630320fd,
                        0xA1A8003936862E7a15092A91898D69fa8bCE290c,
                        0x206B25Ea01E188Ee243131aFdE526bA6E131a016,
                        0x25F21A1f97607Edf6852339fad709728cffb9a9d
                    ),
                    ISortedOracles(sortedOracles)
                )
            );

            BiPoolManagerProxy(biPoolManagerProxy)._setAndInitializeImplementation(
                biPoolManager,
                abi.encodeWithSelector(
                    BiPoolManager(0).initialize.selector,
                    brokerProxy,
                    IReserve(reserveProxy),
                    ISortedOracles(sortedOracles),
                    IBreakerBox(breakerBox)
                )
            );

            BrokerProxy(brokerProxy)._setAndInitializeImplementation(
                broker,
                abi.encodeWithSelector(
                    Broker(0).initialize.selector,
                    Arrays.addresses(biPoolManagerProxy),
                    reserveProxy
                )
            );

            ReserveProxy(reserveProxy)._setAndInitializeImplementation(
                reserve,
                abi.encodeWithSelector(
                    Reserve(0).initialize.selector,
                    reserveInitCalldata()
                )
            );

            StableTokenProxy(stableTokenProxy)._setImplementation(stableToken);
            StableTokenEURProxy(stableTokenProxy)._setImplementation(stableToken);
            StableTokenBRLProxy(stableTokenProxy)._setImplementation(stableToken);
            IStableTokenV2(stableTokenProxy).initializeV2(
                brokerProxy,
                address(0),
                address(0)
            );
            IStableTokenV2(stableTokenEURProxy).initializeV2(
                brokerProxy,
                address(0),
                address(0)
            );
            IStableTokenV2(stableTokenBRLProxy).initializeV2(
                brokerProxy,
                address(0),
                address(0)
            );

            IReserve(reserveProxy).addExchangeSpender(brokerProxy);
            IReserve(reserveProxy).addExchangeSpender(0x268C754bb4Ee50dCa0aF1E81e6B3eDA3c8Be93db);
            IReserve(reserveProxy).addToken(stableTokenProxy);
            IReserve(reserveProxy).addToken(stableTokenEURProxy);
            IReserve(reserveProxy).addToken(stableTokenBRLProxy);


            Config.Pool memory allPoolConfig = [
                aUSDPlanq_PoolConfig(),
                aEURPlanq_PoolConfig(),
                aBRLPlanq_PoolConfig(),
                aUSDUSDC_PoolConfig(),
                aEURUSDC_PoolConfig(),
                aBRLUSDC_PoolConfig()];

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
                config: IBiPoolManager.PoolConfig({
                spread: FixidityLib.wrap(poolConfig.spread.unwrap()),
                referenceRateFeedID: poolConfig.referenceRateFeedID,
                referenceRateResetFrequency: poolConfig.referenceRateResetFrequency,
                minimumReports: poolConfig.minimumReports,
                stablePoolResetSize: poolConfig.stablePoolResetSize
                })
                });
                IBiPoolManager(biPoolManagerProxy).createExchange(pool);
            }

            IBreakerBox(breakerBoxProxy).addBreaker(address(medianDeltaBreaker), 1);
            IBreakerBox(breakerBoxProxy).addBreaker(address(valueDeltaBreaker), 2);

            Config.RateFeed memory rateFeedConfig = [
                PLQUSD_RateFeedConfig(),
                PLQEUR_RateFeedConfig(),
                PLQBRL_RateFeedConfig(),
                USDCUSD_RateFeedConfig(),
                USDCEUR_RateFeedConfig(),
                USDCBRL_RateFeedConfig()
            ];

            MedianDeltaBreaker.setCooldownTime(
            Arrays.addresses(
                rateFeedConfig[0].rateFeedID,
                rateFeedConfig[1].rateFeedID,
                rateFeedConfig[2].rateFeedID,
                rateFeedConfig[3].rateFeedID,
                rateFeedConfig[4].rateFeedID,
                rateFeedConfig[5].rateFeedID
                ),
            Arrays.uints(
                rateFeedConfig[0].medianDeltaBreaker0.cooldown,
                rateFeedConfig[1].medianDeltaBreaker0.cooldown,
                rateFeedConfig[2].medianDeltaBreaker0.cooldown,
                rateFeedConfig[3].valueDeltaBreaker0.cooldown,
                rateFeedConfig[4].medianDeltaBreaker0.cooldown,
                rateFeedConfig[5].medianDeltaBreaker0.cooldown
                )
            );

            MedianDeltaBreaker.setRateChangeThresholds(
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

            ValueDeltaBreaker.setReferenceValues(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.referenceValue)
            );

            ValueDeltaBreaker.setCooldownTimes(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.cooldown)
            );

            ValueDeltaBreaker.setRateChangeThresholds(
                Arrays.addresses(rateFeedConfig[3].rateFeedID),
                Arrays.uints(rateFeedConfig[3].valueDeltaBreaker0.threshold.unwrap())
            );

            for (uint256 i = 0; i < rateFeedConfig.length; i++) {

                if (rateFeedConfig[i].medianDeltaBreaker0.enabled) {
                    IBreakerBox(breakerBoxProxy).toggleBreaker(medianDeltaBreaker, rateFeedConfig[i].rateFeedID, true);
                }
                if (rateFeedConfig[i].valueDeltaBreaker0.enabled) {
                    IBreakerBox(breakerBoxProxy).toggleBreaker(valueDeltaBreaker, rateFeedConfig[i].rateFeedID, true);
                }
            }

            ISortedOracles(sortedOracles).setBreakerBox(breakerBoxProxy);

            for (uint256 i = 0; i < allPoolConfig.length; i++) {
                Config.Pool memory poolConfig = allPoolConfig[i];
                IBroker(brokerProxy).configureTradingLimit(
                    getExchangeId(poolConfig.asset0,poolConfig.asset1, poolConfig.isConstantSum),
                    poolConfig.asset0,
                    TradingLimits.Config({
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

        console2.log("----------");
        console2.log("BrokerProxy deployed at: ", brokerProxy);
        console2.log("BiPoolManagerProxy deployed at: ", biPoolManagerProxy);
        console2.log("BreakerBoxProxy deployed at: ", breakerBoxProxy);
        console2.log("ReserveProxy deployed at: ", reserveProxy);
        console2.log("StableTokenProxy deployed at: ", stableTokenProxy);
        console2.log("StableTokenEURProxy deployed at: ", stableTokenEURProxy);
        console2.log("StableTokenBRLProxy deployed at: ", stableTokenBRLProxy);
        console2.log("ConstantSumPricingModule deployed at: ", address(csPricingModule));
        console2.log("ConstantProductPricingModule deployed at: ", address(cpPricingModule));
        console2.log("MedianDeltaBreaker deployed at", address(medianDeltaBreaker));
        console2.log("ValueDeltaBreaker deployed at", address(valueDeltaBreaker));
        console2.log("BreakerBox deployed at: ", breakerBox);
        console2.log("BiPoolManager deployed at: ", biPoolManager);
        console2.log("Broker deployed at: ", broker);
        console2.log("Reserve deployed at: ", reserve);
        console2.log("StableTokenV2 deployed at: ", stableToken);
        console2.log("----------");
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

    function reserveInitCalldata() internal pure returns (bytes memory) {
        Config.PartialReserve partialReserve;

        partialReserve.registryAddress = address(0x9DabFe01de024C681320eb80FBc64EccEaa58ca2);
        partialReserve.tobinTaxStalenessThreshold = 3153600000;
        partialReserve.assetAllocationSymbols = Arrays.bytes32s(
        bytes32("PLQ")
        );
        partialReserve.assetAllocationWeights = Arrays.uints(
        uint256(1 * 10 ** 24)
        );
        partialReserve.tobinTax = FixidityLib.newFixed(0).unwrap();
        partialReserve.tobinTaxReserveRatio = FixidityLib.newFixed(0).unwrap();
        partialReserve.frozenPlanq = 0;
        partialReserve.frozenDays = 0;
        partialReserve.spendingRatioForPlanq = FixidityLib.fixed1().unwrap();

        partialReserve.collateralAssets = Arrays.addresses(contracts.planqRegistry("BridgedUSDC"), contracts.planqRegistry("PlanqToken"));
        partialReserve.collateralAssetDailySpendingRatios = Arrays.uints(FixidityLib.fixed1().unwrap(), FixidityLib.fixed1().unwrap());

        return abi.encodeWithSelector(
            Reserve(0).initialize.selector,
            partialReserve.registryAddress,
            partialReserve.tobinTaxStalenessThreshold,
            partialReserve.spendingRatioForPlanq,
            partialReserve.frozenPlanq,
            partialReserve.frozenDays,
            partialReserve.assetAllocationSymbols,
            partialReserve.assetAllocationWeights,
            partialReserve.tobinTax,
            partialReserve.tobinTaxReserveRatio,
            partialReserve.collateralAssets,
            partialReserve.collateralAssetDailySpendingRatios
        );
    }

    function aUSDPlanq_PoolConfig() internal view returns (Config.Pool memory config) {
        config = Config.Pool({
            asset0: contracts.planqRegistry("StableToken"),
            asset1: contracts.planqRegistry("PlanqToken"),
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
            asset0: contracts.planqRegistry("StableTokenEUR"),
            asset1: contracts.planqRegistry("PlanqToken"),
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
            asset0: contracts.planqRegistry("StableTokenBRL"),
            asset1: contracts.planqRegistry("PlanqToken"),
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
            asset0: contracts.planqRegistry("StableToken"),
            asset1: contracts.dependency("BridgedUSDC"),
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
            asset0: contracts.celoRegistry("StableTokenEUR"),
            asset1: contracts.dependency("BridgedUSDC"),
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
            asset0: contracts.celoRegistry("StableTokenBRL"),
            asset1: contracts.dependency("BridgedUSDC"),
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
