// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ITVLOracle {
    function getTotalValueLockedInternalByToken(
        address tokenAddress,
        address tier2Address
    ) 
        external 
        view 
        returns (uint256);

    function getTotalValueLockedAggregated(uint256 optionIndex)
        external
        view
        returns (uint256);
}
