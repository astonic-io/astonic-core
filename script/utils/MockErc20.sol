// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import { ERC20 } from "openzeppelin-contracts-next/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "openzeppelin-contracts-next/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint8 decimals) public ERC20(name, symbol) {
        mint(msg.sender, 100_000_000 ether);
    }

    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }
}
