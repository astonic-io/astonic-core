// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
/**
@dev Fork tests for Astonic!
This test suite tests invariants on a fork of a live Astonic environment.

Thare are two types of test contracts:
- ChainForkTests: Tests that are specific to the chain, such as the number of exchanges, the number of collateral
  assets, contract initialization state, etc.
- ExchangeForkTests: Tests that are specific to the exchange, such as trading limits, swaps, circuit breakers, etc.

To make it easier to debug and develop, we have one ChainForkTest for each chain (Alfajores, Planq) and
one ExchangeForkTest for each exchange provider and exchange pair.

The ChainForkTests are instantiated with:
- Chain ID.
- Expected number of exchange providers.
- Expected number of exchanges per exchange provider.
If any of these assertions fail, then the ChainForkTest will fail and that's the cue to update this file
and add additional ExchangeForkTests.

The ExchangeForkTests are instantiated with:
- Chain ID.
- Exchange Provider Index.
- Exchange Index.

And the naming convention for them is:
- ${ChainName}_P${ExchangeProviderIndex}E${ExchangeIndex}_ExchangeForkTest
- e.g. "Alfajores_P0E00_ExchangeForkTest (Alfajores, Exchange Provider 0, Exchange 0)"
The Exchange Index is 0 padded to make them align nicely in the file.
Exchange provider counts shouldn't exceed 10. If they do, then we need to update the naming convention.

This makes it easy to drill into which exchange is failing and debug it like:
- `$ env FOUNDRY_PROFILE=fork-tests forge test --match-contract PLANQ_P0E12`
or run all tests for a chain:
- `$ env FOUNDRY_PROFILE=fork-tests forge test --match-contract Alfajores`
*/

import { PLANQ_ID, ALFAJORES_ID } from "test/utils/Constants.sol";
import { uints } from "contracts/libraries/Array.sol";
import { ChainForkTest } from "./ChainForkTest.sol";
import { ExchangeForkTest } from "./ExchangeForkTest.sol";
import { BancorExchangeProviderForkTest } from "./BancorExchangeProviderForkTest.sol";
import { GoodDollarTradingLimitsForkTest } from "./GoodDollar/TradingLimitsForkTest.sol";
import { GoodDollarSwapForkTest } from "./GoodDollar/SwapForkTest.sol";
import { GoodDollarExpansionForkTest } from "./GoodDollar/ExpansionForkTest.sol";
import { LockingUpgradeForkTest } from "./upgrades/LockingUpgradeForkTest.sol";

contract Alfajores_ChainForkTest is ChainForkTest(ALFAJORES_ID, 1, uints(16)) {}

contract Alfajores_P0E00_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 0) {}

contract Alfajores_P0E01_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 1) {}

contract Alfajores_P0E02_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 2) {}

contract Alfajores_P0E03_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 3) {}

contract Alfajores_P0E04_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 4) {}

contract Alfajores_P0E05_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 5) {}

contract Alfajores_P0E06_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 6) {}

contract Alfajores_P0E07_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 7) {}

contract Alfajores_P0E08_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 8) {}

contract Alfajores_P0E09_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 9) {}

contract Alfajores_P0E10_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 10) {}

contract Alfajores_P0E11_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 11) {}

contract Alfajores_P0E12_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 12) {}

contract Alfajores_P0E13_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 13) {}

contract Alfajores_P0E14_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 14) {}

contract Alfajores_P0E15_ExchangeForkTest is ExchangeForkTest(ALFAJORES_ID, 0, 15) {}

contract Planq_ChainForkTest is ChainForkTest(PLANQ_ID, 1, uints(16)) {}

contract Planq_P0E00_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 0) {}

contract Planq_P0E01_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 1) {}

contract Planq_P0E02_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 2) {}

contract Planq_P0E03_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 3) {}

contract Planq_P0E04_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 4) {}

contract Planq_P0E05_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 5) {}

contract Planq_P0E06_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 6) {}

contract Planq_P0E07_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 7) {}

contract Planq_P0E08_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 8) {}

contract Planq_P0E09_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 9) {}

contract Planq_P0E10_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 10) {}

contract Planq_P0E11_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 11) {}

contract Planq_P0E12_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 12) {}

contract Planq_P0E13_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 13) {}

contract Planq_P0E14_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 14) {}

contract Planq_P0E15_ExchangeForkTest is ExchangeForkTest(PLANQ_ID, 0, 15) {}

contract Planq_BancorExchangeProviderForkTest is BancorExchangeProviderForkTest(PLANQ_ID) {}

contract Planq_GoodDollarTradingLimitsForkTest is GoodDollarTradingLimitsForkTest(PLANQ_ID) {}

contract Planq_GoodDollarSwapForkTest is GoodDollarSwapForkTest(PLANQ_ID) {}

contract Planq_GoodDollarExpansionForkTest is GoodDollarExpansionForkTest(PLANQ_ID) {}

contract Planq_LockingUpgradeForkTest is LockingUpgradeForkTest(PLANQ_ID) {}
