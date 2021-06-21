// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWrapper {
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount
    ) external payable returns (address, uint256);

    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount
    ) external payable returns (uint256);
}
