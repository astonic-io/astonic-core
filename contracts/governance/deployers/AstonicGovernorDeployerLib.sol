// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable max-line-length

import { AstonicGovernor } from "../AstonicGovernor.sol";

library AstonicGovernorDeployerLib {
  /**
   * @notice Deploys a new AstonicGovernor contract
   * @return The address of the new AstonicGovernor contract
   */
  function deploy() external returns (AstonicGovernor) {
    return new AstonicGovernor();
  }
}
