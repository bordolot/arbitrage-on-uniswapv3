//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

import {console} from "forge-std/Test.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV3Pool {
    // IUniswapV3PoolState
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    // IUniswapV3PoolActions
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract FlashCaller {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    constructor() {}

    function makeFlash(
        address _pool3AddrForLoan,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        IUniswapV3Pool(_pool3AddrForLoan).flash(
            address(this),
            _amount0,
            _amount1,
            _data
        );
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external {
        //@todo create a code that in assemble decode data encoded with abi.encodePacked()
        (
            address _borrowTokenAddr,
            bool _zeroForOneStart,
            uint256 _amountIn,
            address _token0Addr,
            address _token1Addr,
            address _pool1Addr,
            address _pool2Addr
        ) = abi.decode(
                data,
                (address, bool, uint256, address, address, address, address)
            );

        // MAKE ARBITRAGE HERE
        console.log("----------");
        console.log("START ARBITRAGE");
        console.log("   START INFO");
        {
            int24 _tick_Info;
            (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool1Addr).slot0();
            console.log(
                "   Pool1 _tick_Info before ARBITRAGE:",
                int256(_tick_Info)
            );
            (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool2Addr).slot0();
            console.log(
                "   Pool2 _tick_Info before ARBITRAGE:",
                int256(_tick_Info)
            );
        }

        console.log("");
        console.log("   MAKE SWAP ON POOL1");
        uint256 _amountOut = _makeSwap(
            _pool1Addr,
            (
                _zeroForOneStart
                    ? abi.encode(_token0Addr)
                    : abi.encode(_token1Addr)
            ),
            _zeroForOneStart,
            _amountIn
        );

        console.log("   received this amount of token1", _amountOut);

        {
            int24 _tick_Info;
            (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool1Addr).slot0();
            console.log("   Pool1 _tick_Info after swap:", int256(_tick_Info));
            // (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool2Addr).slot0();
            // console.log("Pool2 _tick_Info after swap:", int256(_tick_Info));
        }

        console.log("");
        console.log("   MAKE SWAP ON POOL2");
        _amountOut = _makeSwap(
            _pool2Addr,
            (
                !_zeroForOneStart
                    ? abi.encode(_token0Addr)
                    : abi.encode(_token1Addr)
            ),
            !_zeroForOneStart,
            _amountOut
        );

        console.log("   received this amount of token0", _amountOut);

        {
            int24 _tick_Info;
            // (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool1Addr).slot0();
            // console.log("Pool1 _tick_Info after 1 swap:", int256(_tick_Info));
            (, _tick_Info, , , , , ) = IUniswapV3Pool(_pool2Addr).slot0();
            console.log(
                "   Pool2 _tick_Info after 1 swap:",
                int256(_tick_Info)
            );
        }

        {
            // REPAY FLASH
            console.log("----------");
            console.log("REPAY FLASH");
            console.log("   profit gross", _amountOut - _amountIn);
            console.log("   flashloan fee0", fee0);
            console.log("   flashloan fee1", fee1);
            // console.log(
            //     "   success?",
            //     (
            //         (fee0 > fee1)
            //             ? (_amountOut - _amountIn > fee0)
            //             : (_amountOut - _amountIn > fee1)
            //     )
            // );

            console.log(
                "   profit net",
                (
                    (fee0 > fee1)
                        ? (
                            (_amountOut - _amountIn > fee0)
                                ? (_amountOut - _amountIn - fee0)
                                : (0)
                        )
                        : (
                            (_amountOut - _amountIn > fee1)
                                ? (_amountOut - _amountIn - fee1)
                                : (0)
                        )
                )
            );
            console.log("   GAS FEES NOT INCLUDED!!!!");

            IERC20(_borrowTokenAddr).transfer(
                msg.sender,
                (_amountIn + ((fee0 > fee1) ? fee0 : fee1))
            );
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        address _tokenAddr = abi.decode(_data, (address));
        uint256 _amountToPay = amount0Delta > 0
            ? (uint256(amount0Delta))
            : (uint256(amount1Delta));
        IERC20(_tokenAddr).transfer(msg.sender, (_amountToPay));
    }

    function _makeSwap(
        address _poolAddr,
        bytes memory _data,
        bool _zeroForOne,
        uint256 _amountIn
    ) internal returns (uint256 _amountOut) {
        (int256 amount0, int256 amount1) = IUniswapV3Pool(_poolAddr).swap(
            address(this),
            _zeroForOne,
            int256(_amountIn),
            (_zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1),
            _data
        );
        _amountOut = uint256(-(_zeroForOne ? amount1 : amount0));
    }
}
