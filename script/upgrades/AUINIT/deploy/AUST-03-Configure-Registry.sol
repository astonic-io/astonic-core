// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import { Arrays } from "script/utils/Arrays.sol";
import { IRegistry } from "contracts/interfaces/IRegistry.sol";
import { IReserve } from "contracts/interfaces/IReserve.sol";
import { IBreakerBox } from "contracts/interfaces/IBreakerBox.sol";
import { IProxy } from "contracts/interfaces/IProxy.sol";
import { ITradingLimits } from "contracts/interfaces/ITradingLimits.sol";
import { ISortedOracles } from "contracts/interfaces/ISortedOracles.sol";
import { PlanqChain } from "script/utils/Chain.sol";
import { Script } from "script/utils/Script.sol";
import { console2 } from "forge-std/Script.sol";
import {Config} from "script/utils/Config.sol";

contract AUST03_CreateContracts is Script {
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
        address brokerProxy = address(0xaD7e1F70f4C9cdbe41516188433dc3Da9A7d1187);
        address reserveProxy = address(0xBc51eCE1F7c7C0c351d413e8162bBA6C9e28A9f6);
        address stableTokenProxy = address(0xA2871B267a7d888F830251F6B4D9d3DFf184995a);
        address stableTokenEURProxy = address(0xd5be2932FEbD73019ba1d5d97DFC35E1Ab09E501);
        address stableTokenBRLProxy = address(0x240642C6f69878A0b199065f25EDf82023BC59ce);
        address breakerBox = address(0x26039b9a3d73184f212f8A4622230a953EE9e51E);


        vm.startBroadcast(PlanqChain.deployerPrivateKey());
        {
            registry.setAddressFor("StableToken", stableTokenProxy);
            registry.setAddressFor("StableTokenEUR", stableTokenEURProxy);
            registry.setAddressFor("StableTokenBRL", stableTokenBRLProxy);
            registry.setAddressFor("Reserve", reserveProxy);
            registry.setAddressFor("Broker", brokerProxy);
            registry.setAddressFor("BreakerBox", breakerBox);
            registry.setAddressFor("BridgedUSDC", address(0xecEEEfCEE421D8062EF8d6b4D814efe4dc898265));

            //"PLQUSDRateFeedAddr": "0x8c86e877e9632cD18a66E8A787f93FB3DE56446c",
            //"PLQEURRateFeedAddr": "0x09535BA317c53caF13fDB6bCAe157E7aBaa894a5",
            //"PLQBRLRateFeedAddr": "0x5bb8157db521739C3294433B6cD71A46630320fd",
            //"USDCUSDRateFeedAddr": "0xA1A8003936862E7a15092A91898D69fa8bCE290c",
            //"USDCEURRateFeedAddr": "0x206B25Ea01E188Ee243131aFdE526bA6E131a016",
            //"USDCBRLRateFeedAddr": "0x25F21A1f97607Edf6852339fad709728cffb9a9d",

        }
        vm.stopBroadcast();

        console2.log("----------");
        console2.log("BrokerProxy deployed at: ", brokerProxy);
        console2.log("ReserveProxy deployed at: ", reserveProxy);
        console2.log("StableTokenProxy deployed at: ", stableTokenProxy);
        console2.log("StableTokenEURProxy deployed at: ", stableTokenEURProxy);
        console2.log("StableTokenBRLProxy deployed at: ", stableTokenBRLProxy);
        console2.log("BreakerBox deployed at: ", breakerBox);
        console2.log("----------");
    }

}
