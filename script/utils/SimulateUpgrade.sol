// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable func-name-mixedcase, contract-name-camelcase
pragma solidity ^0.8;

import { console } from "forge-std-next/console.sol";
import { Contracts } from "script/utils/Contracts.sol";
import { IAstonicUpgrade } from "script/interfaces/IAstonicUpgrade.sol";
import { IGovernanceFactory } from "script/interfaces/IGovernanceFactory.sol";
import { GovernanceScript } from "script/utils/Script.sol";
import { Chain } from "script/utils/Chain.sol";

interface IScript {
    function run() external;
}

contract SimulateUpgrade is GovernanceScript {
    using Contracts for Contracts.Cache;

    function run(string memory _upgrade) public {
        fork();

        address governance = IGovernanceFactory(Chain.governanceFactory()).governanceTimelock();
        IAstonicUpgrade upgrade = IAstonicUpgrade(factory.create(_upgrade));
        upgrade.prepare();

        simulateProposal(upgrade.buildProposal(), governance);
        if (upgrade.hasChecks()) {
            IScript checks = IScript(factory.create(string(abi.encodePacked(_upgrade, "Checks"))));
            checks.run();
        }
    }

    function check(string memory _upgrade) public {
        IAstonicUpgrade upgrade = IAstonicUpgrade(factory.create(_upgrade));
        if (upgrade.hasChecks()) {
            IScript checks = IScript(factory.create(string(abi.encodePacked(_upgrade, "Checks"))));
            checks.run();
        } else {
            console.log("No checks for %s", _upgrade);
        }
    }
}
