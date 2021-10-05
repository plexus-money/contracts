// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPlexusOracle {
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

    function getStakableTokens()
        external
        view
        returns (address[] memory, string[] memory);

    function getAPR(
        address tier2Address, 
        address tokenAddress
    )
        external
        view
        returns (uint256);

    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) 
        external 
        view 
        returns (uint256);

    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) 
        external 
        view 
        returns (uint256);

    function getTokenPrice(address tokenAddress)
        external
        view
        returns (uint256);

    function getUserWalletBalance(
        address userAddress, 
        address tokenAddress
    )
        external
        view
        returns (uint256);
        
    function getAddress(string memory) external view returns (address);
}
