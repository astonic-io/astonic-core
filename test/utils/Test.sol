// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 💬 ABOUT
// Astonic's default Test.

// 🧩 MODULES
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Chains} from "./Chains.sol";
// 📦 BOILERPLATE
import {TestBase} from "forge-std/Base.sol";

// ⭐️ TEST
abstract contract Test is TestBase, StdAssertions, StdCheats, StdInvariant, StdUtils, Chains {
    // Note: IS_TEST() must return true.
    bool public IS_TEST = true;
}
