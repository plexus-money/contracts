// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IPlexusOracle.sol";
import "./interfaces/staking/ITokenRewards.sol";
import "./interfaces/staking/ITier2Staking.sol";

// Tier1FarmController contract on Mainnet: 0x97b00db19bAe93389ba652845150CAdc597C6B2F

contract Tier1FarmController is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address payable public admin;
    address ETH_TOKEN_ADDRESS;
    mapping (string => address) public tier2StakingContracts;
    uint256 public commission; // Default is 4 percent
    IPlexusOracle private oracle;
    address public oracleAddress;
    string public farmName;
    mapping(address => uint256) private totalAmountStaked;

    constructor() payable {
    }

    function initialize(address _tier2StakingContracts_farm, address _oracleAddress) initializeOnceOnly public {
        ETH_TOKEN_ADDRESS  = address(0x0);
        commission  = 400; // Default is 4 percent
        farmName = 'Tier1Aggregator';
        tier2StakingContracts["FARM"] = _tier2StakingContracts_farm;
        updateOracleAddress(_oracleAddress);
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    modifier onlyAdmin {
        require(
             msg.sender == oracle.getAddress("CORE"),
             "Only owner can call this function."
        );
        _;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function updateOracleAddress(address newOracleAddress) public onlyOwner returns (bool) {
        oracleAddress = newOracleAddress;
        oracle = IPlexusOracle(newOracleAddress);
        return true;
    }

    function addOrEditTier2ChildStakingContract(
        string memory name,
        address stakingAddress
    ) public onlyOwner returns (bool) {
        tier2StakingContracts[name] = stakingAddress;
        return true;
    }

    function addOrEditTier2ChildsChildStakingContract(
        address tier2Contract,
        string memory name,
        address stakingAddress,
        address stakingToken
    ) public onlyOwner returns (bool) {
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        tier2Con.addOrEditStakingContract(name, stakingAddress, stakingToken);
        return true;
    }

    function updateCommissionTier2(address tier2Contract, uint256 amount) public onlyOwner returns (bool) {
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        tier2Con.updateCommission(amount);
        return true;
    }

    function deposit(
        string memory tier2ContractName,
        address tokenAddress,
        uint256 amount,
        address payable onBehalfOf
    ) public payable onlyAdmin nonZeroAmount(amount) returns (bool) {
        address tier2Contract = tier2StakingContracts[tier2ContractName];
        IERC20 thisToken = IERC20(tokenAddress);
        thisToken.safeTransferFrom(msg.sender, address(this), amount);

        // approve the tier2 contract to handle tokens from this account
        thisToken.safeIncreaseAllowance(tier2Contract, 0);
        thisToken.safeIncreaseAllowance(tier2Contract, amount.mul(100));

        ITier2Staking tier2Con = ITier2Staking(tier2Contract);

        tier2Con.deposit(tokenAddress, amount, onBehalfOf);

        address rewardsContract = oracle.getAddress("REWARDS");

        if (rewardsContract != address(0x0)) {
            ITokenRewards rewards = ITokenRewards(rewardsContract);
            if (rewards.checkIfTokenIsWhitelistedForStaking(tokenAddress)) {
                rewards.stakeDelegated(amount, tokenAddress, onBehalfOf);
            }
        }
        return true;
    }

    function withdraw(
        string memory tier2ContractName,
        address tokenAddress,
        uint256 amount,
        address payable onBehalfOf
    ) public payable onlyAdmin nonZeroAmount(amount) returns (bool) {
        address tier2Contract = tier2StakingContracts[tier2ContractName];
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        tier2Con.withdraw(tokenAddress, amount, onBehalfOf);
        address rewardsContract = oracle.getAddress("REWARDS");
        if (rewardsContract != address(0x0)) {
            ITokenRewards rewards = ITokenRewards(rewardsContract);
            if (rewards.checkIfTokenIsWhitelistedForStaking(tokenAddress)) {
                rewards.unstakeAndClaimDelegated(
                    onBehalfOf,
                    tokenAddress,
                    onBehalfOf
                );
            }
        }
        return true;
    }

    function changeTier2Owner(
        address payable tier2Contract,
        address payable newOwner
    ) public onlyOwner returns (bool) {
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        tier2Con.changeOwner(newOwner);
        return true;
    }

    function adminEmergencyWithdrawTokensTier2(
        address payable tier2Contract,
        address token,
        uint256 amount,
        address payable destination
    ) public onlyOwner nonZeroAmount(amount) returns (bool) {
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        tier2Con.adminEmergencyWithdrawTokens(token, amount, destination);
        return true;
    }

    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    ) public onlyOwner nonZeroAmount(amount) returns (bool) {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }

        return true;
    }

    function getStakedPoolBalanceByUser(
        string memory tier2ContractName,
        address _owner,
        address tokenAddress
    ) public view returns (uint256) {
        address tier2Contract = tier2StakingContracts[tier2ContractName];
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        uint256 balance = tier2Con.getStakedPoolBalanceByUser(_owner, tokenAddress);
        return balance;
    }

    function getDepositBalanceByUser(
        string calldata tier2ContractName,
        address _owner,
        address token
    ) external view returns (uint256) {
        address tier2Contract = tier2StakingContracts[tier2ContractName];
        IERC20 thisToken = IERC20(token);
        ITier2Staking tier2Con = ITier2Staking(tier2Contract);
        uint256 balance = tier2Con.depositBalances(_owner, token);
        return balance;
    }
}
