// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable func-name-mixedcase, contract-name-camelcase, function-max-lines, var-name-mixedcase
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "../../../../contracts/governance/AstonicToken.sol";
import "../../../utils/Script.sol";
import { PlanqChain } from "script/utils/Chain.sol";
import { Contracts } from "script/utils/Contracts.sol";

import { GovernanceScript } from "script/utils/Script.sol";
import { IAstonicUpgrade, IPlanqGovernance } from "script/interfaces/IAstonicUpgrade.sol";
import { IGovernanceFactory } from "script/interfaces/IGovernanceFactory.sol";
import { console } from "forge-std/console.sol";

interface IProxyAdminLite {
    function getProxyAdmin(address proxy) external view returns (address);

    function changeProxyAdmin(address proxy, address newAdmin) external;
}

contract AU02 is IAstonicUpgrade, GovernanceScript {
    using Contracts for Contracts.Cache;

    bool public hasChecks = true;

    address public astonicGovernor;
    address public astonicTokenAddress;
    address public lockingProxy;

    address public oldLockingProxyAdmin;

    AstonicToken public astonicToken;
    IGovernanceFactory public governanceFactory;

    /**
     * @dev Loads the contracts from previous deployments
   */
    function loadDeployedContracts() public {
        // Load load deployment with governance factory
        contracts.loadSilent("AUGOV-00-Create-Factory", "latest");
    }

    function prepare() public {
        loadDeployedContracts();

        // Get and set the governance factory
        address governanceFactoryAddress = contracts.deployed("GovernanceFactory");

        governanceFactory = IGovernanceFactory(governanceFactoryAddress);

        // Get the astonic governor address
        astonicGovernor = governanceFactory.astonicGovernor();

        astonicTokenAddress = governanceFactory.astonicToken();
        astonicToken = AstonicToken(astonicTokenAddress);

        require(astonicGovernor != address(0), "AstonicGovernor address not found");
        require(astonicTokenAddress != address(0), "AstonicGovernor address not found");
    }

    function run() public {
        prepare();

        IPlanqGovernance.Transaction[] memory _transactions = buildProposal();

        vm.startBroadcast(PlanqChain.deployerPrivateKey());
        {
            createStructuredProposal(
                "AGP-1: Unpause Astonic Token",
                "script/upgrades/AUINIT/deploy/AGP1.md",
                _transactions,
                astonicGovernor
            );
        }
        vm.stopBroadcast();
    }

    function buildProposal() public returns (IPlanqGovernance.Transaction[] memory) {
        IPlanqGovernance.Transaction[] memory _transactions = new IPlanqGovernance.Transaction[](1);

        _transactions[0] = IPlanqGovernance.Transaction(
            0,
            astonicTokenAddress,
            abi.encodeWithSelector(AstonicToken.unpause.selector)
        );

        return _transactions;
    }
}
