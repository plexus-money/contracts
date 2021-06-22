// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IStaking1 {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function getReservesList() external view returns (address[] memory);

    function getUserAccountData(address user) external view returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function withdraw( address asset, uint256 amount, address to) external returns (uint256);
}