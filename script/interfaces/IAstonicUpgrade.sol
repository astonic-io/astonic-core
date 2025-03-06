// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

import { IPlanqGovernance } from "./IPlanqGovernance.sol";

interface IAstonicUpgrade {
    function buildProposal() external returns (IPlanqGovernance.Transaction[] memory);

    function prepare() external;

    function hasChecks() external returns (bool);
}
