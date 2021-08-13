// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IRemix {

    function remix(
        address lpTokenPairAddress,
        address unwrapOutputToken,
        address[] memory destinationTokens,
        address[][] memory unwrapPaths,
        address[][] memory wrapPaths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        external
        payable
        returns (uint256);

}  
