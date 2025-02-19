// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Vm} from "forge-std/Vm.sol";
import {StdChains} from "forge-std/StdChains.sol";
import "./Constants.sol";

abstract contract Chains is StdChains {
    Vm private constant vm = Vm(VM_ADDRESS);

    bool private celoChainsInitialized;

    /// @notice Get deployer private key for the current chain.
    /// @return private key of the deployer.
    function deployerPrivateKey() internal returns (uint256) {
        Chain memory chain = getChain(block.chainid);
        string memory pkEnvVar = string(
            abi.encodePacked(chain.chainAlias, "_DEPLOYER_PK")
        );
        return vm.envUint(pkEnvVar);
    }

    /// @notice Get deployer address for the current chain.
    /// @return address of the deployer.
    function deployerAddress() internal returns (address payable) {
        return payable(address(uint160(vm.addr(deployerPrivateKey()))));
    }

    /// @notice Setup a fork environment for the current chain.
    function fork() internal {
        initializeCeloChains();
        StdChains.Chain memory chain = getChain();
        uint256 forkId = vm.createFork(chain.rpcUrl);
        vm.selectFork(forkId);
    }

    /// @notice Setup a fork environment for a chain.
    function fork(uint256 chainId) internal {
        initializeCeloChains();
        StdChains.Chain memory chain = getChain(chainId);
        uint256 forkId = vm.createFork(chain.rpcUrl);
        vm.selectFork(forkId);
    }

    /// @notice Setup a fork environment for a chain, at a specific block height.
    function fork(uint256 chainId, uint256 blockHeight) internal {
        initializeCeloChains();
        StdChains.Chain memory chain = getChain(chainId);
        uint256 forkId = vm.createFork(chain.rpcUrl, blockHeight);
        vm.selectFork(forkId);
    }

    /// @notice Determine if the current chain is Celo.
    /// @return true if the current chain is Celo.
    function isCelo() public view returns (bool) {
        return block.chainid == PLANQ_ID;
    }

    /// @notice Determine if the current chain is Baklava.
    /// @return true if the current chain is Baklava.
    function isBaklava() public view returns (bool) {
        return block.chainid == BAKLAVA_ID;
    }

    /// @notice Determine if the current chain is Alfajores.
    /// @return true if the current chain is Alfajores.
    function isAlfajores() public view returns (bool) {
        return block.chainid == ALFAJORES_ID;
    }

    /// @notice Configures Celo related in StdChains.
    function initializeCeloChains() internal {
        if (celoChainsInitialized) return;
        celoChainsInitialized = true;

        setChain("planq", StdChains.ChainData("Planq", PLANQ_ID, ""));
        setChain(
            "alfajores",
            StdChains.ChainData("Celo Alfajores Testnet", ALFAJORES_ID, "")
        );
        setChain(
            "baklava",
            StdChains.ChainData("Celo Baklava Testnet", BAKLAVA_ID, "")
        );
    }

    /// @dev Override getChain to initialize Celo chains before lookup.
    function getChain(
        uint256 chainId
    ) internal override returns (Chain memory) {
        initializeCeloChains();
        return super.getChain(chainId);
    }

    // @notice Get the current chain.
    function getChain() internal virtual returns (Chain memory) {
        return getChain(block.chainid);
    }
}
