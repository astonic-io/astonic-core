// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import { Test } from "test/utils/Test.sol";
import { PLANQ_REGISTRY_ADDRESS } from "test/utils/Constants.sol";

import { IRegistry } from "contracts/interfaces/IRegistry.sol";

interface IRegistryInit {
  function initialize() external;
}

contract WithRegistry is Test {
  IRegistry public registry = IRegistry(PLANQ_REGISTRY_ADDRESS);

  constructor() {
    deployCodeTo("Registry", abi.encode(true), PLANQ_REGISTRY_ADDRESS);
    IRegistryInit(PLANQ_REGISTRY_ADDRESS).initialize();
  }
}
