// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IExternalPlatform.sol";
import "./interfaces/uniswap/IUniswapV2RouterLite.sol";
import "./interfaces/staking/ITokenRewards.sol";
import "./interfaces/ITVLOracle.sol";

/// @title Plexus Oracle Contract
/// @author Team Plexus
contract PlexusOracle is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Oracle state variables
    string[] public farmTokenPlusFarmNames;
    address[] public farmAddresses;
    address[] public farmTokens;
    address public uniswapAddress;
    address public rewardAddress;
    address public coreAddress;
    address public tier1Address;
    address private usdcCoinAddress;
    address private tvlOracleAddress;
    mapping (string  => address) public platformDirectory;
    mapping (string => address) private farmDirectoryByName;
    mapping (address => mapping(address =>uint256)) private farmManuallyEnteredAPYs;
    mapping (address => mapping (address  => address )) private farmOracleObtainedAPYs;
    IUniswapV2RouterLite private uniswap;
    ITokenRewards private reward;
    ITVLOracle private tvlOracle;

    constructor() payable {
    }

    /**
     * @notice Executed on a call to the contract if none of the other 
     * functions match the given function signature, or if no data was 
     * supplied at all and there is no receive Ether function
     */
    fallback() external payable {
    }

    /**
     * @notice Function executed on plain ether transfers and on a call to the 
     * contract with empty calldata 
     */
    receive() external payable {
    }

    /**
     * @notice Initialize the core contract 
     * @param _uniswap Address to the Uniswap V2 router contract 
     * @param _usdc Address to the USDC token contract
     */
    function initialize(address _uniswap, address _usdc) external initializeOnceOnly {
        uniswapAddress = _uniswap;
        uniswap = IUniswapV2RouterLite(uniswapAddress);
        usdcCoinAddress = _usdc;
    }

    /**
     * @notice Allow contract owner to update the address to the TVL oracle
     * contract
     * @param theAddress Address to the updated TVL Oracle contract */
    function updateTVLAddress(address theAddress) external onlyOwner returns (bool) {
        tvlOracleAddress = theAddress;
        tvlOracle = ITVLOracle(theAddress);
        updateDirectory("TVLORACLE", theAddress);
        return true;
    }

    /**
     * @notice Allow contract owner to update the address to the Price oracle
     * contract
     * @param theAddress Address to the updated Price Oracle contract */
    function updatePriceOracleAddress(address theAddress) external onlyOwner returns (bool) {
        uniswapAddress = theAddress;
        uniswap = IUniswapV2RouterLite(theAddress);
        updateDirectory("UNISWAP", theAddress);
        return true;
    }

    /**
     * @notice Allow contract owner to update the address to the USDC token
     * contract
     * @param theAddress Address to the updated USDC token contract */
    function updateUSD(address theAddress) external onlyOwner returns (bool) {
        usdcCoinAddress = theAddress;
        updateDirectory("USD", theAddress);
        return true;
    }

    /**
     * @notice Allow contract owner to update the address to the token rewards
     * contract
     * @param theAddress Address to the updated token rewards contract */
    function updateRewardAddress(address theAddress) external onlyOwner returns (bool) {
        rewardAddress = theAddress;
        reward = ITokenRewards(theAddress);
        updateDirectory("REWARDS", theAddress);
        return true;
    }

    /**
     * @notice Allow contract owner to update the address to the Plexus core
     * contract
     * @param theAddress Address to the updated Plexus core contract */
    function updateCoreAddress(address theAddress) external onlyOwner returns (bool) {
        coreAddress = theAddress;
        updateDirectory("CORE", theAddress);
        return true;
    }

    /**
     * @notice Allow contract owner to update the address to the Tier 1
     * controller contract
     * @param theAddress Address to the updated Tier 1 controller contract */
    function updateTier1Address(address theAddress) external onlyOwner returns (bool) {
        tier1Address = theAddress;
        updateDirectory("TIER1", theAddress);
        return true;
    }

    /** 
     * @notice Add farming platform details to the oracle contract registries 
     * @param name Farm platform name
     * @param farmAddress Address to the farming contract
     * @param farmToken Address to the token contract deposited in the farm
     * @param platformAddress Address to the farm platform contract
     */
    function setPlatformContract(
        string memory name,
        address farmAddress,
        address farmToken,
        address platformAddress
    ) external onlyOwner returns (bool) {
        farmTokenPlusFarmNames.push(name);
        farmAddresses.push(farmAddress);
        farmTokens.push(farmToken);

        farmOracleObtainedAPYs[farmAddress][farmToken] = platformAddress;
        farmDirectoryByName[name] = platformAddress;

        return true;
    }

    /**
     * @notice Bulk modify all farming platform details
     * @param theNames Array of names to the updated farming platforms */
    function replaceAllStakableDirectory(
        string[] memory theNames,
        address[] memory theFarmAddresses,
        address[] memory theFarmTokens
    ) external onlyOwner returns (bool) {
        farmTokenPlusFarmNames = theNames;
        farmAddresses = theFarmAddresses;
        farmTokens = theFarmTokens;
        return true;
    }

    /**
     * @notice Retrieve the TVL for a given token from the specified Tier 2
     * contract
     * @param tokenAddress Address to the given token for which the TVL is to 
     * be retrieved 
     * @param tier2Address Address to the Tier 2 contract to retrieve the TVL
     * from
     * @return TVL for the given token from the specified Tier 2 contract
     */
    function getTotalValueLockedInternalByToken(
        address tokenAddress,
        address tier2Address
    ) external view returns (uint256) {
        uint256 result = tvlOracle.getTotalValueLockedInternalByToken(tokenAddress, tier2Address);
        return result;
    }

    function getTotalValueLockedAggregated(uint256 optionIndex) external view returns (uint256) {
        uint256 result = tvlOracle.getTotalValueLockedAggregated(optionIndex);
        return result;
    }

    /**
     * @notice Retrieve details about all tokens that can be staked 
     * @return Two arrays - one containing a list of addresses to all tokens 
     * that can be staked and another containing their respective token names 
     */
    function getStakableTokens() external view returns (address[] memory, string[] memory) {
        address[] memory stakableAddrs = farmAddresses;
        string[] memory stakableNames = farmTokenPlusFarmNames;
        return (stakableAddrs, stakableNames);
    }

    /**
     * @notice Retrieve the amount of a given token staked by a particular user
     * using a specified Tier 2 contract
     * @param tokenAddress Address to the given token for which the staked 
     * amount is to be retrieved
     * @param userAddress Address to the user's wallet
     * @param tier2Address Address to the Tier 2 contract used to stake the 
     * specified tokens 
     * @return Amount of specified tokens staked by the given user via the
     * provided Tier 2 contract
     */
    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) external view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(tier2Address);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

    /**
     * @notice Retrieve the rewards accumulated by a given user for a specified 
     * token deposited in a particular Tier 2 contract 
     * @param userAddress Address to the user's wallet
     * @param tokenAddress Address to the token for which reward value is to be
     * retrieved 
     * @param tier2FarmAddress Address to the Tier 2 contract where the given 
     * token was deposited
     * @return Rewards accumulated by the given user for the particular token 
     * from the specified Tier 2 contract address 
     */
    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) external view returns (uint256) {
        uint256 userStartTime = reward.depositBalancesDelegated(userAddress, tokenAddress, 0);

        uint256 principalAmount = reward.depositBalancesDelegated(userAddress, tokenAddress, 1);
        uint256 apr = reward.tokenAPRs(tokenAddress);
        uint256 result = reward.calculateRewards(
            userStartTime, 
            block.timestamp, 
            principalAmount, 
            apr
        );
        return result;
    }

    /** 
     * @notice Retrieve the current price of a token
     * @param tokenAddress Address to the token for which the price is to be 
     * retrieved
     * @return Current price of the specified token 
     */
    function getTokenPrice(address tokenAddress, uint256 amount) external view returns (uint256) {
        address[] memory addresses = new address[](2);
        addresses[0] = tokenAddress;
        addresses[1] = usdcCoinAddress;
        uint256[] memory amounts = getUniswapPrice(addresses, amount);
        uint256 resultingTokens = amounts[1];
        return resultingTokens;
    }

    /**
     * @notice Retrieve the balance of a given token from a specified user
     * wallet 
     * @param userAddress Address to the user's wallet 
     * @param tokenAddress Address to the token for which the balance is to be 
     * retrieved
     * @return Balance of the given token in the specified user wallet
     */
    function getUserWalletBalance(
        address userAddress, 
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    /**
     * @notice Retrieve the commission rates for a given platform
     * @param platformContract Address to the given platform contract
     * @return Commission rate for the given platform contract 
     */
    function getCommissionByContract(address platformContract) external view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.commission();
    }

    function getTotalStakedByContract(
        address platformContract,
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.totalAmountStaked(tokenAddress);
    }
    
    /**
     * @notice Retrieve the amount of a given token deposited by a specified 
     * using a particular platform
     * @param platformContract Address to the platform where the tokens were
     * deposited
     * @param tokenAddress Address to the contract for the deposited token
     * @param userAddress Address to the user's wallet
     * @return The amount of tokens deposited by the given user via the 
     * provided platform contract
     */
    function getAmountCurrentlyDepositedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.depositBalances(userAddress, tokenAddress);
    }

    /**
     * @notice Retrieve the amount of a given token staked by a specified 
     * using a particular platform
     * @param platformContract Address to the platform where the tokens were
     * staked
     * @param tokenAddress Address to the contract for the staked token
     * @param userAddress Address to the user's wallet
     * @return The amount of tokens staked by the given user via the 
     * provided platform contract
     */
    function getAmountCurrentlyFarmStakedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

   /**
     * @notice Retrieve the balance of a given token for a specified user
     * @param userAddress Address to the user's wallet 
     * @param tokenAddress Address to the token for which the balance is to be 
     * retrieved
     * @return Balance of the given token in the specified user wallet
     */
    function getUserTokenBalance(
        address userAddress, 
        address tokenAddress
    ) 
        external 
        view 
        returns (uint256) 
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    /** 
     * @notice Allows contract owner to update the contract address for a given 
     * platform 
     * @param name String identifier for the platform
     * @param theAddress New address to the platform contract
     */
    function updateDirectory(
        string memory name, 
        address theAddress
    ) 
        public 
        onlyOwner 
        returns (bool) 
    {
        platformDirectory[name] = theAddress;
        return true;
    }

    /**
     * @notice Retrieve the APR yield for a given token from a specified
     * yield farm
     * @param farmAddress Address to the specified yield farm contract
     * @param farmToken Address to the given token for which the APR
     * yield is to be retrieved 
     * @return APR yield for the given token address from the specified yield 
     * farm
     */
    function getAPR(address farmAddress, address farmToken) public view returns (uint256) {
        uint256 obtainedAPY = farmManuallyEnteredAPYs[farmAddress][farmToken];

        if (obtainedAPY == 0) {
            IExternalPlatform exContract = IExternalPlatform(
                farmOracleObtainedAPYs[farmAddress][farmToken]
            );
            try exContract.getAPR(farmAddress, farmToken) returns (uint256 apy) {
                return apy;
            } catch (bytes memory) {
                return (0);
            }
        } else {
            return obtainedAPY;
        }
    }

    /**
     * @notice Retrieve the given platform component's address
     * @param component String identifier for the given platform component 
     * @return Address to the given platform component
     */
    function getAddress(string memory component) public view returns (address) {
        return platformDirectory[component];
    }

    /** 
     * @notice Calculate the DAOs commission earnings for a given amount 
     * @param amount Amount value to compute the commission for
     * @param commission Current DAO commission rate
     * @return Commission amount earned by the DAO
     */
    function calculateCommission(
        uint256 amount, 
        uint256 commission
    ) 
        public 
        pure 
        returns (uint256) 
    {
        uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
        return commissionForDAO;
    }

    /**
     * @notice Given an input asset amount and an array of token addresses, 
     * calculates all subsequent maximum output token amounts for each pair of 
     * token addresses in the path
     * @param theAddresses Array of token contract addresses in the path
     * @param amount Given input asset amount 
     * @return amounts1 Array containing maximum output token amounts for each
     * pair of token addresses in the swap path
     */
    function getUniswapPrice(
        address[] memory theAddresses, 
        uint256 amount
    ) 
        internal 
        view 
        returns (uint256[] memory amounts1) 
    {
        uint256[] memory amounts = uniswap.getAmountsOut(amount, theAddresses);
        return amounts;
    }
}