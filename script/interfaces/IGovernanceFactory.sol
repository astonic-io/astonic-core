// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

interface IGovernanceFactory {
    /// @dev Parameters for the initial token allocation
    struct AstonicTokenAllocationParams {
        uint256 airgrabAllocation;
        uint256 astonicTreasuryAllocation;
        address[] additionalAllocationRecipients;
        uint256[] additionalAllocationAmounts;
    }

    function createGovernance(
        address watchdogMultiSig_,
        bytes32 airgrabRoot,
        address fractalSigner,
        AstonicTokenAllocationParams calldata allocationParams
    ) external;

    function astonicToken() external view returns (address);

    function emission() external view returns (address);

    function airgrab() external view returns (address);

    function governanceTimelock() external view returns (address);

    function astonicGovernor() external view returns (address);

    function locking() external view returns (address);

    function proxyAdmin() external view returns (address);
}
