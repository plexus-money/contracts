// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface StakingInterface {
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function deposit ( uint256 _amount ) external;
  function depositAll (  ) external;
  function withdraw ( uint256 _shares ) external;
  function withdrawAll (  ) external;
}

contract Tier2AggregatorFarmController{

  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  address payable public owner;
  address public platformToken = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
  address public tokenStakingContract = 0x09FC573c502037B149ba87782ACC81cF093EC6ef;
  address ETH_TOKEN_ADDRESS  = address(0x0);
  mapping (string => address) public stakingContracts;
  mapping (address => address) public tokenToFarmMapping;
  mapping (string => address) public stakingContractsStakingToken;
  mapping (address => mapping (address => uint256)) public depositBalances;
  uint256 public commission  = 400; // Default is 4 percent


  string public farmName = 'Pickle.Finance';
  mapping (address => uint256) public totalAmountStaked;

  modifier onlyOwner {
         require(
             msg.sender == owner,
             "Only owner can call this function."
         );
         _;
 }






  constructor() public payable {
        stakingContracts["USDTPICKLEJAR"] = 0x09FC573c502037B149ba87782ACC81cF093EC6ef;
        stakingContractsStakingToken ["USDTPICKLEJAR"] = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
        tokenToFarmMapping[stakingContractsStakingToken ["USDTPICKLEJAR"]] =  stakingContracts["USDTPICKLEJAR"];
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
      commission = amount;
      return true;
  }

  function deposit(address tokenAddress, uint256 amount, address onBehalfOf) payable onlyOwner public returns (bool){


       if(tokenAddress == 0x0000000000000000000000000000000000000000){

            depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress]  + msg.value;

             stake(amount, onBehalfOf, tokenAddress );
             totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);
             emit Deposit(onBehalfOf, amount, tokenAddress);
            return true;

        }

        IERC20 thisToken = IERC20(tokenAddress);
        thisToken.safeTransferFrom(msg.sender, address(this), amount);

        depositBalances[onBehalfOf][tokenAddress] = depositBalances[onBehalfOf][tokenAddress]  + amount;

        uint256 approvedAmount = thisToken.allowance(address(this), tokenToFarmMapping[tokenAddress]);
        if(approvedAmount < amount  ){
            thisToken.approve(tokenToFarmMapping[tokenAddress], amount.mul(10000000));
        }
        stake(amount, onBehalfOf, tokenAddress );

        totalAmountStaked[tokenAddress] = totalAmountStaked[tokenAddress].add(amount);

        emit Deposit(onBehalfOf, amount, tokenAddress);
        return true;
   }

   function stake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool){

      StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);
      staker.deposit(amount);
      return true;

   }

   function unstake(uint256 amount, address onBehalfOf, address tokenAddress) internal returns(bool){
      StakingInterface staker  =  StakingInterface(tokenToFarmMapping[tokenAddress]);
      staker.approve(tokenToFarmMapping[tokenAddress], 1000000000000000000000000000000);
      staker.withdrawAll();
      return true;

   }


   function getStakedPoolBalanceByUser(address _owner, address tokenAddress) public view returns(uint256){
        StakingInterface staker  = StakingInterface(tokenToFarmMapping[tokenAddress]);

        uint256 numberTokens = staker.balanceOf(address(this));

        uint256 usersBalancePercentage = (depositBalances[_owner][tokenAddress].mul(1000000)).div(totalAmountStaked[tokenAddress]);
        uint256 numberTokensPlusRewardsForUser= (numberTokens.mul(1000).mul(usersBalancePercentage)).div(1000000000);


        return numberTokensPlusRewardsForUser;

    }


  function withdraw(address tokenAddress, uint256 amount, address payable onBehalfOf) onlyOwner payable public returns(bool){

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



 function kill() virtual public onlyOwner {

         selfdestruct(owner);

 }


    event Deposit(address indexed user, uint256 amount, address token);
    event Withdrawal(address indexed user, uint256 amount, address token);




}
