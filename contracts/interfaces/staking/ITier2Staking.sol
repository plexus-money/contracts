// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ITier2Staking {
    // Staked balance info
    function depositBalances(address _owner, address token)
        external
        view
        returns (uint256 balance);
        
    function getStakedBalances(address _owner, address token)
        external
        view
        returns (uint256 balance);

    function getStakedPoolBalanceByUser(address _owner, address tokenAddress)
        external
        view
        returns (uint256 balance);

    // Basic info
    function tokenToFarmMapping(address tokenAddress)
        external
        view
        returns (address stakingContractAddress);
    function stakingContracts(string calldata platformName)
        external
        view
        returns (address stakingAddress);
    function stakingContractsStakingToken(string calldata platformName)
        external
        view
        returns (address tokenAddress);

    function platformToken() external view returns (address tokenAddress);
    function owner() external view returns (address ownerAddress);

    // Actions
    function deposit(
        address tokenAddress,
        uint256 amount,
        address onBehalfOf
    ) external payable returns (bool);

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address payable onBehalfOf
    ) external payable returns (bool);

    function addOrEditStakingContract(
        string calldata name,
        address stakingAddress,
        address stakingToken
    ) external returns (bool);

    function updateCommission(uint256 amount) external returns (bool);
    function changeOwner(address payable newOwner) external returns (bool);

    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    ) external returns (bool);

    function kill() external;
}
