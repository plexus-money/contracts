// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IRemix {

   function createWrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool remixing
    )
        external
        payable
        returns (address,uint256);

}  
