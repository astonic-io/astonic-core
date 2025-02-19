// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable func-name-mixedcase, var-name-mixedcase, state-visibility, const-name-snakecase, max-states-count
pragma solidity ^0.8;

import { ProtocolTest } from "./ProtocolTest.sol";

import { IERC20 } from "contracts/interfaces/IERC20.sol";

// forge test --match-contract BrokerGasTest -vvv
contract BrokerGasTest is ProtocolTest {
  address trader = makeAddr("trader");

  function setUp() public override {
    super.setUp();

    deal(address(cUSDToken), trader, 10 ** 22, true); // Mint 10k to trader
    deal(address(cEURToken), trader, 10 ** 22, true); // Mint 10k to trader

    deal(address(planqToken), trader, 1000 * 10 ** 18); // Gift 10k to trader

    deal(address(planqToken), address(reserve), 10 ** 24); // Gift 1Mil to reserve
    deal(address(usdcToken), address(reserve), 10 ** 24); // Gift 1Mil to reserve
  }

  /**
   * @notice Test helper function to do swap in
   */
  function doSwapIn(bytes32 poolId, uint256 amountIn, address tokenIn, address tokenOut) public {
    // Get exchange provider from broker
    address[] memory exchangeProviders = broker.getExchangeProviders();
    assertEq(exchangeProviders.length, 1);
    changePrank(trader);
    IERC20(tokenIn).approve(address(broker), amountIn);

    broker.swapIn(address(exchangeProviders[0]), poolId, tokenIn, tokenOut, 1000 * 10 ** 18, 0);
  }

  function test_gas_swapIn_cUSDToBridgedUSDC() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cUSDToken));
    IERC20 tokenOut = IERC20(address(usdcToken));
    bytes32 poolId = pair_cUSD_bridgedUSDC_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_cEURToBridgedUSDC() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cEURToken));
    IERC20 tokenOut = IERC20(address(usdcToken));
    bytes32 poolId = pair_cEUR_bridgedUSDC_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_cEURTocUSD() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cEURToken));
    IERC20 tokenOut = IERC20(address(cUSDToken));
    bytes32 poolId = pair_cUSD_cEUR_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_cUSDTocEUR() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cUSDToken));
    IERC20 tokenOut = IERC20(address(cEURToken));
    bytes32 poolId = pair_cUSD_cEUR_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_PLANQTocEUR() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(planqToken));
    IERC20 tokenOut = IERC20(address(cEURToken));
    bytes32 poolId = pair_cEUR_PLQ_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_PLANQTocUSD() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(planqToken));
    IERC20 tokenOut = IERC20(address(cUSDToken));
    bytes32 poolId = pair_cUSD_PLQ_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_CUSDToPlanq() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cUSDToken));
    IERC20 tokenOut = IERC20(address(planqToken));
    bytes32 poolId = pair_cUSD_PLQ_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }

  function test_gas_swapIn_CEURToPlanq() public {
    uint256 amountIn = 1000 * 10 ** 18; // 1k
    IERC20 tokenIn = IERC20(address(cEURToken));
    IERC20 tokenOut = IERC20(address(planqToken));
    bytes32 poolId = pair_cEUR_PLQ_ID;

    doSwapIn(poolId, amountIn, address(tokenIn), address(tokenOut));
  }
}
