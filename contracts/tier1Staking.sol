// SPDX-License-Identifier: MIT
//Mainnet: 0x97b00db19bAe93389ba652845150CAdc597C6B2F
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface Tier2StakingInterface {

  //staked balance info
  function depositBalances(address _owner, address token) external view returns(uint256 balance);
  function getStakedBalances(address _owner, address token) external view returns(uint256 balance);
  function getStakedPoolBalanceByUser(address _owner, address tokenAddress) external view returns(uint256);

  //basic info
  function tokenToFarmMapping(address tokenAddress) external view returns(address stakingContractAddress);
  function stakingContracts(string calldata platformName) external view returns(address stakingAddress);
  function stakingContractsStakingToken(string calldata platformName) external view returns(address tokenAddress);
  function platformToken() external view returns(address tokenAddress);
  function owner() external view returns(address ownerAddress);

  //actions
  function deposit(address tokenAddress, uint256 amount, address onBehalfOf) payable external returns (bool);
  function withdraw(address tokenAddress, uint256 amount, address payable onBehalfOf) payable external returns(bool);
  function addOrEditStakingContract(string calldata name, address stakingAddress, address stakingToken ) external  returns (bool);
  function updateCommission(uint amount) external  returns(bool);
  function changeOwner(address payable newOwner) external returns (bool);
  function adminEmergencyWithdrawTokens(address token, uint amount, address payable destination) external returns(bool);
  function kill() virtual external;
}
interface Oracle {
  function getAddress(string memory) view external returns (address);

}

interface Rewards {
  function unstakeAndClaimDelegated(address onBehalfOf, address tokenAddress, address recipient) external returns (uint256);
  function stakeDelegated(uint256 amount, address tokenAddress, address onBehalfOf) external returns(bool);
  function checkIfTokenIsWhitelistedForStaking(address tokenAddress) external view returns(bool);
}

contract Tier1FarmController{

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address payable public owner;
  address payable public admin;
  address ETH_TOKEN_ADDRESS  = address(0x0);
  mapping (string => address) public tier2StakingContracts;
  uint256 public commission  = 400; // Default is 4 percent
  Oracle oracle;
  address public oracleAddress;

  string public farmName = 'Tier1Aggregator';
  mapping (address => uint256) totalAmountStaked;

  modifier nonZeroAmount(uint256 amount) {
		require(amount > 0, "Amount specified is zero");
		_;
	}

  modifier onlyOwner {
         require(
             msg.sender == owner,
             "Only owner can call this function."
         );
         _;
  }

 modifier onlyAdmin {
         require(
             msg.sender == oracle.getAddress("CORE"),
             "Only owner can call this function."
         );
         _;
 }


  constructor() public payable {
        tier2StakingContracts["FARM"] = 0x618fDCFF3Cca243c12E6b508D9d8a6fF9018325c;

        owner= payable(msg.sender);
        updateOracleAddress(0xBDfF00110c97D0FE7Fefbb78CE254B12B9A7f41f);

  }


  fallback() external payable {


  }

 function updateOracleAddress(address newOracleAddress ) public onlyOwner returns (bool){
    oracleAddress= newOracleAddress;
    oracle = Oracle(newOracleAddress);
    return true;

  }


  function addOrEditTier2ChildStakingContract(string memory name, address stakingAddress ) public onlyOwner returns (bool){

    tier2StakingContracts[name] = stakingAddress;
    return true;

  }

  function addOrEditTier2ChildsChildStakingContract(address tier2Contract, string memory name, address stakingAddress, address stakingToken ) public onlyOwner returns (bool){

    Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
    tier2Con.addOrEditStakingContract(name, stakingAddress, stakingToken);
    return true;

  }

  function updateCommissionTier2(address tier2Contract, uint amount) public onlyOwner returns(bool){
    Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
    tier2Con.updateCommission(amount);
    return true;
  }





  function deposit(string memory tier2ContractName, address tokenAddress, uint256 amount, address payable onBehalfOf) 
  public payable
  onlyAdmin
  nonZeroAmount(amount) 
  returns (bool){

    address tier2Contract = tier2StakingContracts[tier2ContractName];
    IERC20 thisToken = IERC20(tokenAddress);
    thisToken.safeTransferFrom(msg.sender, address(this), amount);
    //approve the tier2 contract to handle tokens from this account
    thisToken.safeIncreaseAllowance(tier2Contract, 0);
    thisToken.safeIncreaseAllowance(tier2Contract, amount.mul(100));

    Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);

    tier2Con.deposit(tokenAddress, amount, onBehalfOf);

    address rewardsContract = oracle.getAddress("REWARDS");

    if(rewardsContract != address(0x0)){
      Rewards rewards = Rewards(rewardsContract);
      if(rewards.checkIfTokenIsWhitelistedForStaking(tokenAddress)) {
          rewards.stakeDelegated(amount, tokenAddress, onBehalfOf);
      }
     
    }
    return true;

  }

  function withdraw(string memory tier2ContractName, address tokenAddress, uint256 amount, address payable onBehalfOf) 
  public payable
  onlyAdmin
  nonZeroAmount(amount) 
  returns(bool){

        address tier2Contract = tier2StakingContracts[tier2ContractName];
        IERC20 thisToken = IERC20(tokenAddress);
        Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
        tier2Con.withdraw(tokenAddress, amount, onBehalfOf);
        address rewardsContract = oracle.getAddress("REWARDS");
        if(rewardsContract != address(0x0)){
          Rewards rewards = Rewards(rewardsContract);
          if(rewards.checkIfTokenIsWhitelistedForStaking(tokenAddress)) {
            rewards.unstakeAndClaimDelegated(onBehalfOf, tokenAddress, onBehalfOf);
          }

        }
     return true;
   }


   function changeTier2Owner(address payable tier2Contract, address payable newOwner) onlyOwner public returns (bool){
     Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
     tier2Con.changeOwner(newOwner);
     return true;
   }

  function changeOwner(address payable newOwner) onlyOwner public returns (bool){
    owner = newOwner;
    return true;
  }


  function adminEmergencyWithdrawTokensTier2(address payable tier2Contract, address token, uint amount, address payable destination) 
  public
  onlyOwner
  nonZeroAmount(amount)
  returns(bool) {
    Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
    tier2Con.adminEmergencyWithdrawTokens(token, amount, destination);
    return true;
  }

  function adminEmergencyWithdrawTokens(address token, uint amount, address payable destination) 
  public
  onlyOwner
  nonZeroAmount(amount) 
  returns(bool) {



      if (address(token) == ETH_TOKEN_ADDRESS) {
          destination.transfer(amount);
      }
      else {
          IERC20 tokenToken = IERC20(token);
          tokenToken.safeTransfer(destination, amount);
      }




      return true;
  }



function getStakedPoolBalanceByUser(string memory tier2ContractName, address _owner, address tokenAddress) public view returns(uint256){
  address tier2Contract = tier2StakingContracts[tier2ContractName];
  IERC20 thisToken = IERC20(tokenAddress);
  Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
  uint balance = tier2Con.getStakedPoolBalanceByUser(_owner, tokenAddress);
  return balance;

}

function getDepositBalanceByUser(string calldata tier2ContractName, address _owner, address token) external view returns(uint256 ){
  address tier2Contract = tier2StakingContracts[tier2ContractName];
  IERC20 thisToken = IERC20(token);
  Tier2StakingInterface tier2Con = Tier2StakingInterface(tier2Contract);
  uint balance = tier2Con.depositBalances(_owner, token);
  return balance;
}



}
