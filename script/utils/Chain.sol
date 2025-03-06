// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import { Vm } from "forge-std/Vm.sol";

library PlanqChain {
    address private constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    // solhint-disable-next-line const-name-snakecase
    Vm public constant vm = Vm(VM_ADDRESS);

    uint256 public constant NETWORK_ANVIL = 0;

    uint256 public constant NETWORK_PLANQ_CHAINID = 7070;
    string public constant NETWORK_PLANQ_CHAINID_STRING = "7070";
    string public constant NETWORK_PLANQ_RPC = "planq";
    string public constant NETWORK_PLANQ_PK_ENV_VAR = "ASTONIC_DEPLOYER_PK";
    address public constant GOVERNANCE_FACTORY_PLANQ = 0x32125b490626231ad9fF9245B23E8345Fb485377;

    /**
     * @notice Get the current chainId
   * @return _chainId the chain id
   */
    function id() internal view returns (uint256 _chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }
    }

    function idString() internal view returns (string memory) {
        uint256 _chainId = id();
        if (_chainId == NETWORK_PLANQ_CHAINID) return NETWORK_PLANQ_CHAINID_STRING;
        revert("unexpected network");
    }

    function rpcToken() internal view returns (string memory) {
        uint256 _chainId = id();
        if (_chainId == NETWORK_PLANQ_CHAINID) return NETWORK_PLANQ_RPC;
        revert("unexpected network");
    }

    function deployerPrivateKey() internal view returns (uint256) {
        uint256 _chainId = id();
        if (_chainId == NETWORK_PLANQ_CHAINID) return vm.envUint(NETWORK_PLANQ_PK_ENV_VAR);
        revert("unexpected network");
    }

    function governanceFactory() internal view returns (address) {
        uint256 _chainId = id();
        if (_chainId == NETWORK_PLANQ_CHAINID) return GOVERNANCE_FACTORY_PLANQ;
        revert("unexpected network");
    }

    function deployerAddr() internal view returns (address payable) {
        return payable(address(uint160(vm.addr(deployerPrivateKey()))));
    }

    /**
     * @notice Setup a fork environment for the current chain
   */
    function fork() internal {
        uint256 forkId = vm.createFork(rpcToken());
        vm.selectFork(forkId);
    }

    function isPlanq() internal view returns (bool) {
        return id() == NETWORK_PLANQ_CHAINID;
    }
}
