// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ITokenRewards {
    function addTokenToWhitelist(address newTokenAddress) external returns (bool);

    function calculateRewards(uint256 timestampStart, uint256 timestampEnd, uint256 principalAmount, uint256 apr) external view returns (uint256);

    function depositBalances(address, address, uint256) external view returns (uint256);

    function depositBalancesDelegated(address, address, uint256) external view returns (uint256);

    function lpTokensInRewardsReserve() external view returns (uint256);

    function owner() external view returns (address);

    function removeTokenFromWhitelist(address tokenAddress) external returns (bool);

    function stake(uint256 amount, address tokenAddress, address onBehalfOf) external returns (bool);

    function stakeDelegated(uint256 amount, address tokenAddress, address onBehalfOf) external returns (bool);

    function stakingLPTokensAddress() external view returns (address);

    function stakingTokenWhitelist(address) external view returns (bool);

    function stakingTokensAddress() external view returns (address);

    function tokenAPRs(address) external view returns (uint256);

    function tokenDeposits(address, address) external view returns (uint256);

    function tokenDepositsDelegated(address, address) external view returns (uint256);

    function tokensInRewardsReserve() external view returns (uint256);

    function unstakeAndClaim(address onBehalfOf, address tokenAddress, address recipient) external returns (uint256);

    function unstakeAndClaimDelegated(address onBehalfOf, address tokenAddress, address recipient) external returns (uint256);

    function updateAPR(uint256 newAPR, address stakedToken) external returns (bool);

    function updateLPStakingTokenAddress(address newAddress) external returns (bool);

    function updateStakingTokenAddress(address newAddress) external returns (bool);

    function checkIfTokenIsWhitelistedForStaking(address tokenAddress) external view returns (bool);
}