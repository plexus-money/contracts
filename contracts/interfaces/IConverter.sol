// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IConverter {
    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount
    ) external payable returns (uint256);

    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount
    ) external payable returns (address, uint256);
}
