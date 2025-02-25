// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
import { GovernanceFactory } from "../../../../contracts/governance/GovernanceFactory.sol";
import { IRegistry } from "../../../../contracts/interfaces/IRegistry.sol";
import { Arrays } from "../../../utils/Arrays.sol";

contract MUGOV_CreateImplementations is Script {
    function run() public {
        IRegistry registry = IRegistry(0x9DabFe01de024C681320eb80FBc64EccEaa58ca2);
        address owner = address(0xe7aB5A40b8Ef85Fa3ff91EEc6444f4472F616887);
        address governanceFactory;

        vm.startBroadcast(vm.envUint("ASTONIC_DEPLOYER_PK"));
        {
            governanceFactory = address(new GovernanceFactory(owner));
            GovernanceFactory(governanceFactory).createGovernance(
            address(0x13809B86e981DdA6f82Fa092d63A623B98917A44),
                getTokenAllocationParams());
        }
        vm.stopBroadcast();

        console2.log("----------");
        console2.log("GovernanceFactory: ", governanceFactory);
        console2.log("----------");
    }

    function getTokenAllocationParams() internal returns (GovernanceFactory.AstonicTokenAllocationParams memory) {
        // ================================ ASTONIC TOKEN ALLOCATION ================================
        // 1. Astonic community Treasury (25% 10year emission, 5% immediately available)        (30%)
        // 2. Astonic Team, Investors, Future Hires, Advisors                                   (15%)
        // 3. Astonic Liquidity Support                                                         (25%)
        // 4. Airdrop to Cosmos community users                                                 (30%)

    GovernanceFactory.AstonicTokenAllocationParams memory params;

    params.additionalAllocationRecipients = Arrays.addresses(
        address(0x268C754bb4Ee50dCa0aF1E81e6B3eDA3c8Be93db), // #2, Astonic Team.
    address(0x13499C1deB7d0f970939ccaF4e6B03431A3b9816) // #3, Liquidity Support.
    );
    params.additionalAllocationAmounts = Arrays.uints(150, 250);

        // #4, Community Airdrop
    params.airgrabAllocation = 300;

        // #1, Astonic Community Treasury.
        // Note that below we only allocate the 5% part for immediate use that goes to governanceTimeLock.
        // The reimaining part of the allocation (25%) is automatically allocated to the Emission contract
        // by AstonicToken.sol during initialization.
    params.astonicTreasuryAllocation = 50;

    return params;
    }
}
