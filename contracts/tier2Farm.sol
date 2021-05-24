// SPDX-License-Identifier: MIT
//contract address mainnet: 0x618fDCFF3Cca243c12E6b508D9d8a6fF9018325c
//This contract will not support rebasing tokens
//transferfroms are required, and thus they must return a bool, therefore USDT is not supported.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface StakingInterface {
  function balanceOf ( address who ) external view returns ( uint256 );
  //function controller (  ) external view returns ( address );
  function exit (  ) external;
  //function lpToken (  ) external view returns ( address );
  function stake ( uint256 amount ) external;
  //function valuePerShare (  ) external view returns ( uint256 );
}

contract Tier2FarmController{

  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  address payable public owner;
  //address public platformToken = 0xa0246c9032bC3A600820415aE600c6388619A14D;
  //address public tokenStakingContract = 0x25550Cccbd68533Fa04bFD3e3AC4D09f9e00Fc50;
  address ETH_TOKEN_ADDRESS  = address(0x0);
  mapping (string => address) public stakingContracts;
  mapping (address => address) public tokenToFarmMapping;
  mapping (string => address) public stakingContractsStakingToken;
  mapping (address => mapping (address => uint256)) public depositBalances;
  uint256 public commission  = 400; // Default is 4 percent


  string public farmName = 'Harvest.Finance';
  mapping (address => uint256) public totalAmountStaked;

  modifier onlyOwner {
         require(
             msg.sender == owner,
             "Only owner can call this function."
         );
         _;
  }

  constructor() public payable {
        stakingContracts["FARM"] = 0x25550Cccbd68533Fa04bFD3e3AC4D09f9e00Fc50;
        stakingContractsStakingToken ["FARM"] = 0xa0246c9032bC3A600820415aE600c6388619A14D;
        tokenToFarmMapping[stakingContractsStakingToken ["FARM"]] =  stakingContracts["FARM"];
        owner= payable(msg.sender);

  }


  fallback() external payable {


  }



  function addOrEditStakingContract(string memory name, address stakingAddress, address stakingToken ) public onlyOwner returns (bool){

    stakingContracts[name] = stakingAddress;
    stakingContractsStakingToken[name] = stakingToken;
    tokenToFarmMapping[stakingToken] = stakingAddress;
    return true;

  }

  function updateCommission(uint amount) public onlyOwner returns(bool){
      require(amount < 2000, "Commission too high");
      commission = amount;
      return true;
  }

  function deposit(address tokenAddress, uint256 amount, address onBehalfOf) payable onlyOwner public returns (bool){




        IERC20 thisToken = IERC20(tokenAddress);
        thisToken.safeTransferFrom(msg.sender, address(this), amount);

        depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress]  + amount;

        uint256 approvedAmount = thisToken.allowance(address(this), tokenToFarmMapping[tokenAddress]);
        if(approvedAmount < amount  ){
            thisToken.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], 0);
            thisToken.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], amount.mul(100));
        }
        stake(amount, onBehalfOf, tokenAddress );

        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);

        emit Deposit(onBehalfOf, amount, tokenAddress);
        return true;
   }

   function stake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool){
      IERC20 tokenStaked = IERC20(tokenAddress);
      tokenStaked.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], 0);
      tokenStaked.safeIncreaseAllowance(tokenToFarmMapping[tokenAddress], amount.mul(2));

      StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
      staker.stake(amount);
      return true;

   }

   function unstake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool){
      StakingInterface staker  =  StakingInterface(tokenToFarmMapping[tokenAddress]);
      staker.exit();
      return true;

   }


   function getStakedPoolBalanceByUser(address _owner, address tokenAddress) public view returns(uint256){
        StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);

        uint256 numberTokens = staker.balanceOf(address(this));

        uint256 usersBalancePercentage = (depositBalances[_owner][tokenAddress].mul(1000000)).div(totalAmountStaked[tokenAddress]);
        uint256 numberTokensPlusRewardsForUser= (numberTokens.mul(1000).mul(usersBalancePercentage)).div(1000000000);


        return numberTokensPlusRewardsForUser;

    }


  function withdraw(address tokenAddress, uint256 amount, address payable onBehalfOf) payable onlyOwner public returns(bool){

      IERC20 thisToken = IERC20(tokenAddress);
      //uint256 numberTokensPreWithdrawal = getStakedBalance(address(this), tokenAddress);

        if(tokenAddress == 0x0000000000000000000000000000000000000000){
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

        thisToken.safeTransfer(onBehalfOf, numberTokensPlusRewardsForUserMinusCommission);
        if(numberTokensPlusRewardsForUserMinusCommission >0){
            thisToken.safeTransfer(owner, commissionForDAO1);
        }


        uint256 remainingBalance = thisToken.balanceOf(address(this));

        if(remainingBalance>0){
            stake(remainingBalance, address(this), tokenAddress);
        }


        emit Withdrawal(onBehalfOf, amount, tokenAddress);
        return true;

   }


   function calculateCommission(uint256 amount) view public returns(uint256){
     uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
     return commissionForDAO;
   }

   function changeOwner(address payable newOwner) onlyOwner public returns (bool){
     owner = newOwner;
     return true;
   }


   function getStakedBalance(address _owner, address tokenAddress) public view returns(uint256){

       StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
       return staker.balanceOf(_owner);
   }



  function adminEmergencyWithdrawTokens(address token, uint amount, address payable destination) public onlyOwner returns(bool) {



      if (address(token) == ETH_TOKEN_ADDRESS) {
          destination.transfer(amount);
      }
      else {
          IERC20 tokenToken = IERC20(token);
          tokenToken.safeTransfer(destination, amount);
      }




      return true;
  }

    event Deposit(address indexed user, uint256 amount, address token);
    event Withdrawal(address indexed user, uint256 amount, address token);
}
