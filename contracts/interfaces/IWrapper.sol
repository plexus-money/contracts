// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWrapper {
    
    struct WrapParams {
        address sourceToken;
        address [] destinationTokens;
        address [] path1;
        address [] path2;
        uint256 amount;
        uint256 [] userSlippageToleranceAmounts;
        uint256 deadline;
    }

    struct UnwrapParams {
        address lpTokenPairAddress;
        address destinationToken;
        address [] path1;
        address [] path2;
        uint256 amount;
        uint256 [] userSlippageToleranceAmounts;
        uint256 deadline;
    }

    struct RemixParams {
        address lpTokenPairAddress;
        address unwrapOutputToken;
        address [] destinationTokens;
        address [] unwrapPath1;
        address [] unwrapPath2;
        address [] wrapPath1;
        address [] wrapPath2;
        uint256 amount;
        uint256 [] userWrapSlippageToleranceAmounts;
        uint256 [] userUnWrapSlippageToleranceAmounts;
        uint256 deadline;
        bool crossDexRemix;
    }

    function wrap(
        WrapParams memory params
    ) 
        external 
        payable 
        returns (address, uint256);

    function unwrap(
        UnwrapParams memory params
    ) 
        external 
        payable 
        returns (uint256);

    function remix(
        RemixParams memory params
    ) 
        external 
        payable 
        returns (uint256);
}
