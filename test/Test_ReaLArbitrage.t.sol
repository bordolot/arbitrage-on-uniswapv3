//SPDX-License-Identifier:MIT

pragma solidity >=0.6.2;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";

import {FlashCaller} from "../src/FlashCaller.sol";
import {SimulateRealArbitrage} from "../src/SimulateRealArbitrage.sol";

/**
1. Run arbitrage-opportunity-seeker project

2. Open `./out/optimalAmounts.json`

3. Get an element from optimalAmounts.json  e.g. :
 
  {
    "block_number": 22876813,
    "poolsForArbitrage": [
      {
        "poolAddr1": "0xD0fC8bA7E267f2bc56044A7715A489d851dC6D78",
        "feeLvl": "3000"
      },
      {
        "poolAddr2": "0xE845469aAe04f8823202b011A848cf199420B4C1",
        "feeLvl": "10000"
      }
    ],
    "tokens": {
      "token0Addr": "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
      "token1Addr": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    },
    "poolYouCanCallFlash": [
      "0x36F7273afb18A3F2fDd07e3Ac1c28E65d7ea8f07",
      true
    ],
    "backupPoolYouCanCallFlash": [
      "0x3470447f3CecfFAc709D3e783A307790b0208d60",
      true
    ],
    "numberOfTokensToStart": "2873000000000000",
    "estimatedProfit": "79782813754892"
  }

fill variables in TestRealArbitrage

 */

contract TestRealArbitrage is Test {
    FlashCaller flashCaller;
    SimulateRealArbitrage simulateRealArbitrage;

    // numberOfTokensToStart
    uint256 AMOUNT_TO_START = 2873000000000000;
    // token0Addr
    address TOKEN0 = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    // token1Addr
    address TOKEN1 = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // poolsForArbitrage -> poolAddr1
    address POOL1 = address(0xD0fC8bA7E267f2bc56044A7715A489d851dC6D78);
    // poolsForArbitrage -> poolAddr2
    address POOL2 = address(0xE845469aAe04f8823202b011A848cf199420B4C1);
    // poolYouCanCallFlash[0]
    // OR if there are no cash in poolYouCanCallFlash
    // backupPoolYouCanCallFlash[0]
    address POOL_FOR_LOAN = address(0x36F7273afb18A3F2fDd07e3Ac1c28E65d7ea8f07);
    // poolYouCanCallFlash[1]
    // OR if there are no cash in poolYouCanCallFlash
    // backupPoolYouCanCallFlash[1]
    bool BORROW_TOKEN0 = true;

    function setUp() public {
        flashCaller = new FlashCaller();
        simulateRealArbitrage = new SimulateRealArbitrage(address(flashCaller));
    }

    function testMakeArbitrage() public {
        simulateRealArbitrage.makeArbitrage(
            AMOUNT_TO_START,
            TOKEN0,
            TOKEN1,
            POOL1,
            POOL2,
            POOL_FOR_LOAN,
            BORROW_TOKEN0
        );
    }
}
