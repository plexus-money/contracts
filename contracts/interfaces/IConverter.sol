// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IConverter {
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) external payable returns (address, uint256);

    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) external payable returns (uint256);

    function wrapV3(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee,
        uint256 deadline
    ) external payable returns (address, uint256);

    function unwrapV3(
        uint256 tokenId,
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) external payable returns (uint256);
}
