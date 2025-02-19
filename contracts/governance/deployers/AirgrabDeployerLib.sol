// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;
// solhint-disable max-line-length

import { Airgrab } from "../Airgrab.sol";

library AirgrabDeployerLib {
  /**
   * @notice Deploys a new Airgrab contract
   * @param airgrabEnds The timestamp when the airgrab ends
   * @param airgrabLockCliff The cliff duration for the airgrabed tokens in weeks
   * @param airgrabLockSlope The slope duration for the airgrabed tokens in weeks
   * @param token_ The token address in the airgrab.
   * @param locking_ The locking contract for veToken.
   * @param astonicTreasury_ The Astonic Treasury address where unclaimed tokens will be refunded to.
   * @return Airgrab The address of the new Airgrab contract
   */
  function deploy(
    uint256 airgrabEnds,
    uint32 airgrabLockCliff,
    uint32 airgrabLockSlope,
    address token_,
    address locking_,
    address airdropVerifier_,
    address payable astonicTreasury_
  ) external returns (Airgrab) {
    return
      new Airgrab(
        airgrabEnds,
        airgrabLockCliff,
        airgrabLockSlope,
        token_,
        locking_,
        airdropVerifier_,
        astonicTreasury_
      );
  }
}
