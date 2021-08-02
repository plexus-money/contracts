// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IConverter {
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) external payable returns (address, uint256);

    function unwrap(
        address sourceToken,
        address destinationToken,
        address lpTokenPairAddress,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) external payable returns (uint256);
}
