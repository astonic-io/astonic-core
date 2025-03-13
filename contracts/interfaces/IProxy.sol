// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.5.13 <0.9.0;

interface IProxy {
    function _setAndInitializeImplementation(address implementation, bytes calldata callbackData) external payable;
    function _getImplementation() external view returns (address implementation);
    function _setImplementation(address implementation) external;
    function _getOwner() external view returns (address owner);
    function _transferOwnership(address newOwner) external;
}
