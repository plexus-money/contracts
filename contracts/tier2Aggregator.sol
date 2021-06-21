// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/staking/IStaking2.sol";

contract Tier2AggregatorFarmController is OwnableUpgradeable {
    using SafeMath for uint256;

    address public platformToken;
    address public tokenStakingContract;
    address private ETH_TOKEN_ADDRESS;
    mapping(string => address) public stakingContracts;
    mapping(address => address) public tokenToFarmMapping;
    mapping(string => address) public stakingContractsStakingToken;
    mapping(address => mapping(address => uint256)) public depositBalances;
    uint256 public commission; // Default is 4 percent

    string public farmName;
    mapping(address => uint256) public totalAmountStaked;

    constructor() payable {
    }
    function initialize(address _tokenStakingContract, address _platformToken) initializeOnceOnly public {
        ETH_TOKEN_ADDRESS  = address(0x0);
        commission  = 400; // Default is 4 percent
        farmName = 'Pickle.Finance';
        tokenStakingContract = _tokenStakingContract;
        platformToken = _platformToken;
        stakingContracts["USDTPICKLEJAR"] = _tokenStakingContract;
        stakingContractsStakingToken["USDTPICKLEJAR"] = _platformToken;
        tokenToFarmMapping[stakingContractsStakingToken["USDTPICKLEJAR"]] = stakingContracts["USDTPICKLEJAR"];
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
        commission = amount;
        return true;
    }

    function deposit(
        address tokenAddress,
        uint256 amount,
        address onBehalfOf
    ) public payable onlyOwner returns (bool) {
        if (tokenAddress == 0x0000000000000000000000000000000000000000) {
            depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress] + msg.value;

            stake(amount, onBehalfOf, tokenAddress);
            totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);
            emit Deposit(onBehalfOf, amount, tokenAddress);
            return true;
        }

        IERC20 thisToken = IERC20(tokenAddress);
        require(
            thisToken.transferFrom(msg.sender, address(this), amount),
            "Not enough tokens to transferFrom or no approval"
        );

        depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress] + amount;

        uint256 approvedAmount = thisToken.allowance(address(this), tokenToFarmMapping[tokenAddress]);
        if (approvedAmount < amount) {
            thisToken.approve(tokenToFarmMapping[tokenAddress], amount.mul(10000000));
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
    ) internal returns (bool) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);
        staker.deposit(amount);
        return true;
    }

    function unstake(
        uint256 amount,
        address onBehalfOf,
        address tokenAddress
    ) internal returns (bool) {
        IStaking2 staker = IStaking2(tokenToFarmMapping[tokenAddress]);
        staker.approve(tokenToFarmMapping[tokenAddress], 1000000000000000000000000000000);
        staker.withdrawAll();
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
    ) public payable onlyOwner returns (bool) {
        IERC20 thisToken = IERC20(tokenAddress);
        // uint256 numberTokensPreWithdrawal = getStakedBalance(address(this), tokenAddress);

        if (tokenAddress == 0x0000000000000000000000000000000000000000) {
            require(
                depositBalances[msg.sender][tokenAddress] >= amount,
                "You didnt deposit enough eth"
            );

            totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].sub(depositBalances[onBehalfOf][tokenAddress]);
            depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress] - amount;
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
        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].sub(depositBalances[onBehalfOf][tokenAddress]);

        depositBalances[onBehalfOf][tokenAddress] = 0;

        require(
            numberTokensPlusRewardsForUserMinusCommission > 0,
            "For some reason numberTokensPlusRewardsForUserMinusCommission is zero"
        );

        require(
            thisToken.transfer(onBehalfOf, numberTokensPlusRewardsForUserMinusCommission),
            "You dont have enough tokens inside this contract to withdraw from deposits"
        );
        if (numberTokensPlusRewardsForUserMinusCommission > 0) {
            thisToken.transfer(owner(), commissionForDAO1);
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
    ) public onlyOwner returns (bool) {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            require(
                token_.transfer(destination, amount), 
                "Token transfer failed"
                );
        }

        return true;
    }

    function kill() public virtual onlyOwner {
        selfdestruct(payable(owner()));
    }

    event Deposit(address indexed user, uint256 amount, address token);
    event Withdrawal(address indexed user, uint256 amount, address token);
}
