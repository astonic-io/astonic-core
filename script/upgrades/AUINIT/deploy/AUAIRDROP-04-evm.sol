// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
import { Arrays } from "../../../utils/Arrays.sol";

interface AirdropVerifier {
    function claimAmount(address claimAddr) external view returns(uint256);
    function claimAmountCosmos(address claimAddr) external view returns(uint256);
    function claimAirdropCosmos(bytes32 message, uint[2] memory signature, uint[2] memory pubkey, address destinationAddress, string memory bech32Address) external returns(uint256);
    function claimAirdrop(address destination) external returns (uint256);
    function isEligible(address addr) external view returns (bool);
    function addEligibleCosmosAddresses(address[] memory eligibleAddresses, uint256[] memory amounts) external;
    function addEligibleAddresses(address[] memory eligibleAddresses, uint256[] memory amounts) external;
}


contract AUAIRDROP_CreateImplementations is Script {
    address[] airdropAddresses;
    uint256[] airdropAmounts;

    address[][] airdropAddressesCosmos;
    uint256[][] airdropAmountsCosmos;

    function run() public {
        AirdropVerifier airdropVerifier = AirdropVerifier(0xE44e70b6De8D9a181305D414569d0C183FAf9Ba9);

        string memory root = vm.projectRoot();
        string memory path = string(abi.encodePacked(root, "/data/airdrop.planq.csv"));
        string memory currentLine = vm.readLine(path);
        uint lines = 202;
        for(uint i = 0; i < lines; i++) {
            (address airdropAddress, uint256 airdropAmount) = parseAirdropCSVLine(currentLine);

            airdropAddresses.push(airdropAddress);
            airdropAmounts.push(airdropAmount);
            if(i > 0 && i % 250 == 0) {
                airdropAddressesCosmos.push(airdropAddresses);
                airdropAmountsCosmos.push(airdropAmounts);
                airdropAmounts = new uint256[](0);
                airdropAddresses = new address[](0);
            }

            currentLine = vm.readLine(path);
        }

        airdropAddressesCosmos.push(airdropAddresses);
        airdropAmountsCosmos.push(airdropAmounts);

        vm.startBroadcast(vm.envUint("ASTONIC_DEPLOYER_PK"));
        {
            for(uint i = 0; i < airdropAddressesCosmos.length; i++) {
                airdropVerifier.addEligibleAddresses(airdropAddressesCosmos[i], airdropAmountsCosmos[i]);
            }
        }
        vm.stopBroadcast();
    }

    function parseAirdropCSVLine(string memory line) internal pure returns (address, uint256) {
        string[] memory splitLine = vm.split(line, ";");

        address airdropAddress = vm.parseAddress(splitLine[0]);
        uint256 airdropAmount = vm.parseUint(splitLine[1]);
        return (airdropAddress, airdropAmount);
    }
}
