//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

import {console} from "forge-std/Test.sol";

import {FlashCaller} from "./FlashCaller.sol";

interface IUniswapV3Pool {
    // IUniswapV3PoolState
    function liquidity() external view returns (uint128);
}

contract SimulateRealArbitrage {
    FlashCaller immutable flashCaller;

    constructor(address flashCallerAddr) {
        flashCaller = FlashCaller(flashCallerAddr);
    }

    function makeArbitrage(
        uint256 _amountToStart,
        address token0,
        address token1,
        address pool_1,
        address pool_2,
        address _pool3AddrForLoan,
        bool _borrowToken0FromPool3
    ) public {
        if (IUniswapV3Pool(_pool3AddrForLoan).liquidity() == 0) {
            revert(
                "liquidity on _pool3AddrForLoan is 0 - Use different pool (POOL_FOR_LOAN) to call flash "
            );
        }
        bytes memory _data = abi.encode(
            token0, // address of borrowed token
            true, // we always start with token0
            _amountToStart,
            token0,
            token1,
            pool_1,
            pool_2
        );
        console.log("----------");
        console.log("CALL FLASH");
        console.log("   We borrow this amount of token0:", _amountToStart);
        // uint gasStart = gasleft();
        if (_borrowToken0FromPool3) {
            // gasStart = gasleft();
            flashCaller.makeFlash(_pool3AddrForLoan, _amountToStart, 0, _data);
        } else {
            // gasStart = gasleft();
            flashCaller.makeFlash(_pool3AddrForLoan, 0, _amountToStart, _data);
        }

        console.log("----------");
        // console.log("gas consumed", (gasStart - gasleft()));
    }
}
