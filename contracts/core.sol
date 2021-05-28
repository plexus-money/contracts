// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/// @notice Oracle interface used to access user and platform statistics 
interface Oracle {
  function getTotalValueLockedInternalByToken(address tokenAddress, address tier2Address) external view returns (uint256);
  function getTotalValueLockedAggregated(uint256 optionIndex) external view returns (uint256);
  function getStakableTokens() view external  returns (address[] memory, string[] memory);
  function getAPR ( address tier2Address, address tokenAddress ) external view returns ( uint256 );
  function getAmountStakedByUser(address tokenAddress, address userAddress, address tier2Address) external view returns(uint256);
  function getUserCurrentReward(address userAddress, address tokenAddress, address tier2FarmAddress) view external returns(uint256);
  function getTokenPrice(address tokenAddress) view external returns(uint256);
  function getUserWalletBalance(address userAddress, address tokenAddress) external view returns (uint256);
}


/** @notice Interface to the Tier-1 Staking contract which acts as a router 
between the core contract and modular Tier-2 contracts without storing any
funds within itself
*/
interface Tier1Staking {
  function deposit ( string memory tier2ContractName, address tokenAddress, uint256 amount, address onBehalfOf ) external payable returns ( bool );
  function withdraw ( string memory tier2ContractName, address tokenAddress, uint256 amount, address onBehalfOf ) external payable returns ( bool );
}


/// @notice Interface to  wrapping/unwrapping converter functions that allow LP-to-LP conversions
interface Converter {
  function unwrap ( address sourceToken, address destinationToken, uint256 amount ) external payable returns ( uint256 );
  function wrap ( address sourceToken, address[] memory destinationTokens, uint256 amount ) external payable returns ( address, uint256 );
}


/// @notice Wrapped Ether interface to wrap ETH into ERC20-compliant WETH
/// @dev Current contract uses WETH9
interface WrappedETH {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

}


/// @title Plexus Core Contract
/// @notice The core contract acts as the main point of contact to deal with all other system contracts
/// @dev Mainnet address: 0x7a72b2C51670a3D77d4205C2DB90F6ddb09E4303
contract Core{
    using SafeERC20 for IERC20;

    /// @notice Mainnet address to the Oracle contract
    address public oracleAddress;

    /// @notice Mainnet address to the Converter contract
    address public converterAddress;

    /// @notice Mainnet address to the Plexus staking address
    address public stakingAddress;

    // Instances of interfaces mentioned above
    Oracle oracle;
    Tier1Staking staking;
    Converter converter;

    /// @notice Placeholder for the 0x0 mainnet address
    address public ETH_TOKEN_PLACEHOLDER_ADDRESS  = address(0x0);

    /// @notice Core contract owner's address
    /// @dev Only this address can call functions with the onlyOwner modifier
    address payable public owner;

    /// @notice Mainnet address to the WETH9 contract
    address public WETH_TOKEN_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    WrappedETH wethToken = WrappedETH(WETH_TOKEN_ADDRESS);
    
    uint256 approvalAmount = 1000000000000000000000000000000;

    // State variables to track re-entrancy
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /// @notice Modifier to ensure the transaction involves a non-zero positive amount of tokens
    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    /// @notice Modifier to restrict access to the owner of the contract
    modifier onlyOwner {
           require(
               msg.sender == owner,
               "Only owner can call this function."
           );
           _;
    }

    /// @notice Modifier to prevent re-entrant exploits
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    constructor() public payable {
        owner= payable(msg.sender);
        setConverterAddress(0x1d17F9007282F9388bc9037688ADE4344b2cC49B);
        _status = _NOT_ENTERED;
    }

    /** @dev For the converter to unwrap ETH when delegate calling. The contract has to be able to accept 
    ETH for this reason. The emergency withdrawal call is to pick any change up for these conversions 
    */
    fallback() external payable { 
    }

    /// @notice Allows the owner to set and update the address to the oracle contract
    function setOracleAddress(address theAddress) public onlyOwner returns(bool){
        oracleAddress = theAddress;
        oracle = Oracle(theAddress);
        return true;
    }

    /// @notice Allows the owner to set and update the address to the staking address contract
    function setStakingAddress(address theAddress) public onlyOwner returns(bool){
        stakingAddress = theAddress;
        staking = Tier1Staking(theAddress);
        return true;
    }

    /// @notice Allows the owner to set and update the address to the converter address contract
    function setConverterAddress(address theAddress) public onlyOwner returns(bool){
        converterAddress = theAddress;
        converter = Converter(theAddress);
        return true;
    }

    /// @notice Allows the owner to set and update the address of the contract owner
    function changeOwner(address payable newOwner) onlyOwner public returns (bool){
        owner = newOwner;
        return true;
    }

    /// @notice Allow users to deposit assets into a Tier-2 contract via Plexus
    /// @param tier2ContractName Reference to Tier-2 contract to deposit assets into
    /// @param tokenAddress Mainnet address for tokens to be deposited
    /// @param amount Amount of tokens to be deposited
    function deposit(string memory tier2ContractName, address tokenAddress, uint256 amount) 
    nonReentrant() 
    nonZeroAmount(amount)
    payable public returns (bool) 
    {
            IERC20 token;
            if(tokenAddress==ETH_TOKEN_PLACEHOLDER_ADDRESS){
                wethToken.deposit{value:msg.value}();
                tokenAddress=WETH_TOKEN_ADDRESS;
                token = IERC20(tokenAddress);
            }
            else{
                token = IERC20(tokenAddress);
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            token.safeIncreaseAllowance(stakingAddress, 0);
            token.safeIncreaseAllowance(stakingAddress, approvalAmount);
            bool result = staking.deposit(tier2ContractName, tokenAddress, amount, msg.sender);
            require(result, "There was an issue in core with your deposit request. Please see logs");
            return result;
    }

    /// @notice Allow users to withdraw assets from Tier-2 contract via Plexus
    /// @param tier2ContractName Reference to Tier-2 contract to withdraw assets from
    /// @param tokenAddress Mainnet address for tokens to be withdrawn
    /// @param amount Amount of tokens to be withdrawn
    function withdraw(string memory tier2ContractName, address tokenAddress, uint256 amount) 
    public payable
    nonReentrant()
    nonZeroAmount(amount) 
    returns(bool)
    {
        bool result = staking.withdraw(tier2ContractName, tokenAddress, amount, msg.sender);
        require(result, "There was an issue in core with your withdrawal request. Please see logs");
        return result;
    }

    /// @notice Allow conversion between LP tokens
    function convert(address sourceToken, address[] memory destinationTokens, uint256 amount) 
    public payable
    nonZeroAmount(amount)
    returns(address, uint256)
    {
        if(sourceToken != ETH_TOKEN_PLACEHOLDER_ADDRESS){
            IERC20 token = IERC20(sourceToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
        }

        ( address destinationTokenAddress, uint256 _amount) = converter.wrap{value:msg.value}(sourceToken, destinationTokens, amount);

        IERC20 token = IERC20(destinationTokenAddress);
        token.safeTransfer(msg.sender, _amount);
        return (destinationTokenAddress, _amount);

    }

    /** @notice Deconversion allows transformation of LP tokens back to non-LP tokens as 
    these cannot simply be swapped via Uniswap */ 
    function deconvert(address sourceToken, address destinationToken, uint256 amount) 
    public payable
    nonZeroAmount(amount)
    returns(uint256)
    {
        uint256 _amount = converter.unwrap{value:msg.value}(sourceToken, destinationToken, amount);
        IERC20 token = IERC20(destinationToken);
        token.safeTransfer(msg.sender, _amount);
        return _amount;
    }

    function getStakableTokens() view public  returns (address[] memory, string[] memory){

        (address [] memory stakableAddresses, string [] memory stakableTokenNames) = oracle.getStakableTokens();
        return (stakableAddresses, stakableTokenNames);

    }

    function getAPR(address tier2Address, address tokenAddress) public view returns(uint256){

        uint256 result = oracle.getAPR(tier2Address, tokenAddress);
        return result;
    }

    function getTotalValueLockedAggregated(uint256 optionIndex) public view returns (uint256){
        uint256 result = oracle.getTotalValueLockedAggregated(optionIndex);
        return result;
    }

    function getTotalValueLockedInternalByToken(address tokenAddress, address tier2Address) public view returns (uint256){
        uint256 result = oracle.getTotalValueLockedInternalByToken( tokenAddress, tier2Address);
        return result;
    }

    function getAmountStakedByUser(address tokenAddress, address userAddress, address tier2Address) public view returns(uint256){
        uint256 result = oracle.getAmountStakedByUser(tokenAddress, userAddress,  tier2Address);
        return result;
    }

    function getUserCurrentReward(address userAddress, address tokenAddress, address tier2FarmAddress) view public returns(uint256){
        return oracle.getUserCurrentReward( userAddress,  tokenAddress, tier2FarmAddress);
    }

    function getTokenPrice(address tokenAddress) view public returns(uint256){
        uint256 result = oracle.getTokenPrice(tokenAddress);
        return result;
    }

    function getUserWalletBalance(address userAddress, address tokenAddress) public view returns (uint256){
        uint256 result = oracle.getUserWalletBalance( userAddress, tokenAddress);
        return result;

    }

    function updateWETHAddress(address newAddress) onlyOwner public returns(bool){
        WETH_TOKEN_ADDRESS = newAddress;
        wethToken= WrappedETH(newAddress);
    }

    function adminEmergencyWithdrawAccidentallyDepositedTokens(address token, uint amount, address payable destination) public onlyOwner returns(bool) {

            if (address(token) == ETH_TOKEN_PLACEHOLDER_ADDRESS) {
                destination.transfer(amount);
            }
            else {
                IERC20 tokenToken = IERC20(token);
                tokenToken.safeTransfer(destination, amount);
            }

            return true;
        }


    }

