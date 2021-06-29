// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IUniswapV2RouterLite {
    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    )
        external
        view
        returns (uint256[] memory amounts);
}