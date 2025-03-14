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


    address sortedOracles = registry.getAddressForString("SortedOracles");


    function run() public {
        address biPoolManagerProxy = address(0x6257f6315Ae36eB88AdD2eB4F886a0A4261Ae1B1);
        address brokerProxy = address(0xaD7e1F70f4C9cdbe41516188433dc3Da9A7d1187);
        address reserveProxy = address(0xBc51eCE1F7c7C0c351d413e8162bBA6C9e28A9f6);
        address stableTokenProxy = address(0xA2871B267a7d888F830251F6B4D9d3DFf184995a);
        address stableTokenEURProxy = address(0xd5be2932FEbD73019ba1d5d97DFC35E1Ab09E501);
        address stableTokenBRLProxy = address(0x240642C6f69878A0b199065f25EDf82023BC59ce);
        address stableToken = address(0xD23Fd338aBA28C1865d77816dE0Ba7482879fC60);
        address breakerBox = address(0x26039b9a3d73184f212f8A4622230a953EE9e51E);
        address biPoolManager = address(0xAa74B934372F770B0975617Bdc5E1CE82eFC84Ad);
        address broker = address(0xb822599237cd7536439523Ae660Dd163De97fC74);
        address reserve = address(0x36D70b7e17e415F854E453E66383944710Ce04cc);

        vm.startBroadcast(PlanqChain.deployerPrivateKey());
        {

            //"PLQUSDRateFeedAddr": "0x8c86e877e9632cD18a66E8A787f93FB3DE56446c",
            //"PLQEURRateFeedAddr": "0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5",
            //"PLQBRLRateFeedAddr": "0x5bb8157db521739C3294433B6cD71A46630320fd",
            //"USDCUSDRateFeedAddr": "0xA1A8003936862E7a15092A91898D69fa8bCE290c",
            //"USDCEURRateFeedAddr": "0x206B25Ea01E188Ee243131aFdE526bA6E131a016",
            //"USDCBRLRateFeedAddr": "0x25F21A1f97607Edf6852339fad709728cffb9a9d",

            // oracle 1 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393
            ISortedOracles(sortedOracles).addOracle(0x8c86e877e9632cD18a66E8A787f93FB3DE56446c, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);
            ISortedOracles(sortedOracles).addOracle(0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);
            ISortedOracles(sortedOracles).addOracle(0x5bb8157db521739C3294433B6cD71A46630320fd, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);
            ISortedOracles(sortedOracles).addOracle(0xA1A8003936862E7a15092A91898D69fa8bCE290c, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);
            ISortedOracles(sortedOracles).addOracle(0x206B25Ea01E188Ee243131aFdE526bA6E131a016, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);
            ISortedOracles(sortedOracles).addOracle(0x25F21A1f97607Edf6852339fad709728cffb9a9d, 0x7C18E81dac0dC7B07F95cca7Eaa84Ce6F1675393);

            // oracle 2 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5
            ISortedOracles(sortedOracles).addOracle(0x8c86e877e9632cD18a66E8A787f93FB3DE56446c, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);
            ISortedOracles(sortedOracles).addOracle(0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);
            ISortedOracles(sortedOracles).addOracle(0x5bb8157db521739C3294433B6cD71A46630320fd, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);
            ISortedOracles(sortedOracles).addOracle(0xA1A8003936862E7a15092A91898D69fa8bCE290c, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);
            ISortedOracles(sortedOracles).addOracle(0x206B25Ea01E188Ee243131aFdE526bA6E131a016, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);
            ISortedOracles(sortedOracles).addOracle(0x25F21A1f97607Edf6852339fad709728cffb9a9d, 0x019553F53724CCeCEFCb7674005d2c68CB9DB3F5);

            // oracle 3 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2
            ISortedOracles(sortedOracles).addOracle(0x8c86e877e9632cD18a66E8A787f93FB3DE56446c, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);
            ISortedOracles(sortedOracles).addOracle(0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);
            ISortedOracles(sortedOracles).addOracle(0x5bb8157db521739C3294433B6cD71A46630320fd, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);
            ISortedOracles(sortedOracles).addOracle(0xA1A8003936862E7a15092A91898D69fa8bCE290c, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);
            ISortedOracles(sortedOracles).addOracle(0x206B25Ea01E188Ee243131aFdE526bA6E131a016, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);
            ISortedOracles(sortedOracles).addOracle(0x25F21A1f97607Edf6852339fad709728cffb9a9d, 0x1272a8be5E55C9fA36E4Cc333b528b012cD17EE2);

            IBreakerBox(breakerBox).addRateFeeds(
                    Arrays.addresses(
                        0x8c86e877e9632cD18a66E8A787f93FB3DE56446c,
                        0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5,
                        0x5bb8157db521739C3294433B6cD71A46630320fd,
                        0xA1A8003936862E7a15092A91898D69fa8bCE290c,
                        0x206B25Ea01E188Ee243131aFdE526bA6E131a016,
                        0x25F21A1f97607Edf6852339fad709728cffb9a9d
                    ));

            IBreakerBox(breakerBox).setSortedOracles(ISortedOracles(sortedOracles));

            IProxy(biPoolManagerProxy)._setAndInitializeImplementation(
                biPoolManager,
                abi.encodeWithSelector(
                    IBiPoolManager(biPoolManager).initialize.selector,
                    brokerProxy,
                    IReserve(reserveProxy),
                    ISortedOracles(sortedOracles),
                    IBreakerBox(breakerBox)
                )
            );

            IProxy(brokerProxy)._setAndInitializeImplementation(
                broker,
                abi.encodeWithSelector(
                    IBroker(address(0)).initialize.selector,
                    Arrays.addresses(biPoolManagerProxy),
                    Arrays.addresses(reserveProxy)
                )
            );


            address[] memory initialBalanceAddresses = new address[](0);
            uint256[] memory initialBalanceValues = new uint256[](0);
            IStableTokenV2(stableTokenProxy).initialize(
                "Astonic USD",
            "aUSD",
                initialBalanceAddresses,
                initialBalanceValues
            );
            IStableTokenV2(stableTokenEURProxy).initialize(
                "Astonic EUR",
            "aEUR",
                initialBalanceAddresses,
                initialBalanceValues
            );
            IStableTokenV2(stableTokenBRLProxy).initialize(
                "Astonic BRL",
            "aBRL",
                initialBalanceAddresses,
                initialBalanceValues
            );
            IStableTokenV2(stableTokenProxy).setBroker(brokerProxy);
            IStableTokenV2(stableTokenEURProxy).setBroker(brokerProxy);
            IStableTokenV2(stableTokenBRLProxy).setBroker(brokerProxy);
        }
        vm.stopBroadcast();

    }
}
