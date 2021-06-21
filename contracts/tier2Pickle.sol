// SPDX-License-Identifier: MIT
//Contract Address: 0xA320c4442542E6CD793Fb5F46c18fB7A6213615C
//PICKLE-UNI-USDT/ETH contract name for parent tier 1
//This contract will not support rebasing tokens

pragma solidity >=0.4.22 <0.8.0;
import "./proxyLib/OwnableUpgradeable.sol";

interface ERC20 {
    function totalSupply() external view returns(uint supply);
    function balanceOf(address _owner) external view returns(uint balance);
    function transfer(address _to, uint _value) external returns(bool success);
    function transferFrom(address _from, address _to, uint _value) external returns(bool success);
    function approve(address _spender, uint _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns(uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface StakingInterface {
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function balanceOf ( address account ) external view returns ( uint256 );
    function deposit ( uint256 _amount ) external;
    function stake ( uint256 _amount ) external;
    function depositAll (  ) external;
    function withdraw  ( uint256 _amount ) external;
    function withdrawAll (  ) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal view returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal view returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Tier2PickleFarmController is OwnableUpgradeable {
    using SafeMath
    for uint256;
    //address payable public owner;
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

    constructor() public payable {
    }

    function initialize() initializeOnceOnly public {
        platformToken = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
        tokenStakingContract = 0xa17a8883dA1aBd57c690DF9Ebf58fC194eDAb66F;
        ETH_TOKEN_ADDRESS  = address(0x0);
        commission  = 400; // Default is 4 percent
        stakingContracts["PICKLE"] = 0xa17a8883dA1aBd57c690DF9Ebf58fC194eDAb66F;
        stakingContractsStakingToken ["PICKLE"] = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
        tokenToFarmMapping[stakingContractsStakingToken ["PICKLE"]] =  stakingContracts["PICKLE"];
    }

    fallback() external payable {}

    function addOrEditStakingContract(string memory name, address stakingAddress, address stakingToken ) public onlyOwner returns (bool) {
        stakingContracts[name] = stakingAddress;
        stakingContractsStakingToken[name] = stakingToken;
        tokenToFarmMapping[stakingToken] = stakingAddress;
        return true;
    }

    function updateCommission(uint amount) public onlyOwner returns(bool) {
        require(amount < 2000, "Commission too high");
        commission = amount;
        return true;
    }

    function deposit(address tokenAddress, uint256 amount, address onBehalfOf) payable onlyOwner public returns (bool) {
        ERC20 thisToken = ERC20(tokenAddress);
        require(thisToken.transferFrom(msg.sender, address(this), amount), "Not enough tokens to transferFrom or no approval");
        depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress]  + amount;
        uint256 approvedAmount = thisToken.allowance(address(this), tokenToFarmMapping[tokenAddress]);

        if (approvedAmount < amount  ) {
            thisToken.approve(tokenToFarmMapping[tokenAddress], 0);
            thisToken.approve(tokenToFarmMapping[tokenAddress], amount.mul(100));
        }

        stake(amount, onBehalfOf, tokenAddress );
        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);
        emit Deposit(onBehalfOf, amount, tokenAddress);

        return true;
    }

    function stake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool) {
        StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
        staker.stake(amount);
        return true;
    }

    function unstake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool) {
        StakingInterface staker  =  StakingInterface(tokenToFarmMapping[tokenAddress]);
        staker.withdraw(amount);
        return true;
    }

    function getStakedPoolBalanceByUser(address _owner, address tokenAddress) public view returns(uint256) {
        StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
        uint256 numberTokens = staker.balanceOf(address(this));
        uint256 usersBalancePercentage = (depositBalances[_owner][tokenAddress].mul(1000000)).div(totalAmountStaked[tokenAddress]);
        uint256 numberTokensPlusRewardsForUser= (numberTokens.mul(1000).mul(usersBalancePercentage)).div(1000000000);

        return numberTokensPlusRewardsForUser;
    }

    function withdraw(address tokenAddress, uint256 amount, address payable onBehalfOf) payable onlyOwner public returns(bool) {
        ERC20 thisToken = ERC20(tokenAddress);
        //uint256 numberTokensPreWithdrawal = getStakedBalance(address(this), tokenAddress);
        if (tokenAddress == 0x0000000000000000000000000000000000000000) {
            require(depositBalances[msg.sender][tokenAddress] >= amount, "You didnt deposit enough eth");
            totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].sub(depositBalances[onBehalfOf][tokenAddress]);
            depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress]  - amount;
            onBehalfOf.send(amount);

            return true;
        }

        require(depositBalances[onBehalfOf][tokenAddress] > 0, "You dont have any tokens deposited");
        //uint256 numberTokensPostWithdrawal = thisToken.balanceOf(address(this));
        //uint256 usersBalancePercentage = depositBalances[onBehalfOf][tokenAddress].div(totalAmountStaked[tokenAddress]);
        uint256 numberTokensPlusRewardsForUser1 = getStakedPoolBalanceByUser(onBehalfOf, tokenAddress);
        uint256 commissionForDAO1 = calculateCommission(numberTokensPlusRewardsForUser1);
        uint256 numberTokensPlusRewardsForUserMinusCommission = numberTokensPlusRewardsForUser1-commissionForDAO1;
        unstake(amount, onBehalfOf, tokenAddress);
        //staking platforms only withdraw all for the most part, and for security sticking to this
        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].sub(depositBalances[onBehalfOf][tokenAddress]);
        depositBalances[onBehalfOf][tokenAddress] = 0;
        require(numberTokensPlusRewardsForUserMinusCommission >0, "For some reason numberTokensPlusRewardsForUserMinusCommission is zero");
        require(thisToken.transfer(onBehalfOf, numberTokensPlusRewardsForUserMinusCommission), "You dont have enough tokens inside this contract to withdraw from deposits");

        if (numberTokensPlusRewardsForUserMinusCommission >0) {
            thisToken.transfer(owner(), commissionForDAO1);
        }

        uint256 remainingBalance = thisToken.balanceOf(address(this));
        if(remainingBalance>0){
            stake(remainingBalance, address(this), tokenAddress);
        }

        emit Withdrawal(onBehalfOf, amount, tokenAddress);

        return true;
    }

    function calculateCommission(uint256 amount) view public returns(uint256) {
        uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
        return commissionForDAO;
    }

    function getStakedBalance(address _owner, address tokenAddress) public view returns(uint256) {
       StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
       return staker.balanceOf(_owner);
    }

    function adminEmergencyWithdrawTokens(address token, uint amount, address payable destination) public onlyOwner returns(bool) {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
          ERC20 tokenToken = ERC20(token);
          require(tokenToken.transfer(destination, amount));
        }

      return true;
    }

    event Deposit(address indexed user, uint256 amount, address token);
    event Withdrawal(address indexed user, uint256 amount, address token);
}
