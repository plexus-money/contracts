// SPDX-License-Identifier: MIT

// PICKLE-UNI-USDT/ETH contract name for parent tier 1
// This contract will not support rebasing tokens

pragma solidity >=0.8.0 <0.9.0;

// Tier2PickleFarmController contract on Mainnet: 0xA320c4442542E6CD793Fb5F46c18fB7A6213615C

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/staking/IStaking2.sol";

contract Tier2PickleFarmController is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public platformToken;
    address public tokenStakingContract;
    address ETH_TOKEN_ADDRESS;
    mapping (string => address) public stakingContracts;
    mapping (address => address) public tokenToFarmMapping;
    mapping (string => address) public stakingContractsStakingToken;
    mapping (address => mapping (address => uint256)) public depositBalances;
    uint256 public commission; // Default is 4 percent
    string public farmName = 'Pickle.Finance';
    mapping (address => uint256) public totalAmountStaked;

    constructor() payable {
    }

    function initialize(address _tokenStakingContract, address _platformToken) initializeOnceOnly public {
        platformToken = _platformToken;
        tokenStakingContract = _tokenStakingContract;
        ETH_TOKEN_ADDRESS  = address(0x0);
        commission  = 400; // Default is 4 percent
        stakingContracts["PICKLE"] = _tokenStakingContract;
        stakingContractsStakingToken["PICKLE"] = _platformToken;
        tokenToFarmMapping[stakingContractsStakingToken["PICKLE"]] = stakingContracts["PICKLE"];
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function addOrEditStakingContract(
        string memory name,
        address stakingAddress,
        address stakingToken
    ) public onlyOwner returns (bool) {
        stakingContracts[name] = stakingAddress;
        stakingContractsStakingToken[name] = stakingToken;
        tokenToFarmMapping[stakingToken] = stakingAddress;
        return true;
    }

    function updateCommission(uint256 amount) public onlyOwner returns (bool) {
        require(amount < 2000, "Commission too high");
        commission = amount;
        return true;
    }

    function deposit(
        address tokenAddress,
        uint256 amount,
        address onBehalfOf
    ) public payable onlyOwner returns (bool) {
        IERC20 thisToken = IERC20(tokenAddress);
        thisToken.safeTransferFrom(msg.sender, address(this), amount);

        depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress] + amount;

        uint256 approvedAmount = thisToken.allowance(address(this), tokenToFarmMapping[tokenAddress]);

        if (approvedAmount < amount) {
            thisToken.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], 0);
            thisToken.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], amount.mul(100));
        }
        stake(amount, onBehalfOf, tokenAddress);

        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);

        emit Deposit(onBehalfOf, amount, tokenAddress);
        return true;
    }

    function stake(
        uint256 amount,
        address onBehalfOf,
        address tokenAddress
    ) internal nonZeroAmount(amount) returns (bool) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);
        staker.stake(amount);
        return true;
    }

    function unstake(
        uint256 amount,
        address onBehalfOf,
        address tokenAddress
    ) internal nonZeroAmount(amount) returns (bool) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);
        staker.withdraw(amount);
        return true;
    }

    function getStakedPoolBalanceByUser(address _owner, address tokenAddress) public view returns (uint256) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);

        uint256 numberTokens = staker.balanceOf(address(this));

        uint256 usersBalancePercentage =
            (depositBalances[_owner][tokenAddress].mul(1000000)).div(
                totalAmountStaked[tokenAddress]
            );
        uint256 numberTokensPlusRewardsForUser =
            (numberTokens.mul(1000).mul(usersBalancePercentage)).div(
                1000000000
            );

        return numberTokensPlusRewardsForUser;
    }

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address payable onBehalfOf
    ) public payable onlyOwner nonZeroAmount(amount) returns (bool) {
        IERC20 thisToken = IERC20(tokenAddress);
        // uint256 numberTokensPreWithdrawal = getStakedBalance(address(this), tokenAddress);

        if (tokenAddress == 0x0000000000000000000000000000000000000000) {
            require(
                depositBalances[msg.sender][tokenAddress] >= amount,
                "You didnt deposit enough eth"
            );

            totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress]
                .sub(depositBalances[onBehalfOf][tokenAddress]);
            depositBalances[onBehalfOf][tokenAddress] =
                depositBalances[onBehalfOf][tokenAddress] -
                amount;
            onBehalfOf.transfer(amount);
            return true;
        }

        require(
            depositBalances[onBehalfOf][tokenAddress] > 0,
            "You dont have any tokens deposited"
        );

        // uint256 numberTokensPostWithdrawal = thisToken.balanceOf(address(this));

        // uint256 usersBalancePercentage = depositBalances[onBehalfOf][tokenAddress].div(totalAmountStaked[tokenAddress]);

        uint256 numberTokensPlusRewardsForUser1 = getStakedPoolBalanceByUser(onBehalfOf, tokenAddress);
        uint256 commissionForDAO1 = calculateCommission(numberTokensPlusRewardsForUser1);
        uint256 numberTokensPlusRewardsForUserMinusCommission = numberTokensPlusRewardsForUser1 - commissionForDAO1;

        unstake(amount, onBehalfOf, tokenAddress);

        // staking platforms only withdraw all for the most part, and for security sticking to this
        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].sub(
            depositBalances[onBehalfOf][tokenAddress]
        );

        depositBalances[onBehalfOf][tokenAddress] = 0;
        require(
            numberTokensPlusRewardsForUserMinusCommission > 0,
            "For some reason numberTokensPlusRewardsForUserMinusCommission is zero"
        );

        thisToken.safeTransfer(onBehalfOf, numberTokensPlusRewardsForUserMinusCommission);

        if (numberTokensPlusRewardsForUserMinusCommission > 0) {
            thisToken.safeTransfer(owner(), commissionForDAO1);
        }

        uint256 remainingBalance = thisToken.balanceOf(address(this));
        if (remainingBalance > 0) {
            stake(remainingBalance, address(this), tokenAddress);
        }

        emit Withdrawal(onBehalfOf, amount, tokenAddress);
        return true;
    }

    function calculateCommission(uint256 amount) public view returns (uint256) {
        uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
        return commissionForDAO;
    }

    function getStakedBalance(address _owner, address tokenAddress) public view returns (uint256) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);
        return staker.balanceOf(_owner);
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

    event Deposit(address indexed user, uint256 amount, address token);
    event Withdrawal(address indexed user, uint256 amount, address token);
}
