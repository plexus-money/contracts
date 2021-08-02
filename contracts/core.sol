// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IPlexusOracle.sol";
import "./interfaces/staking/ITier1Staking.sol";
import "./interfaces/IConverter.sol";
import "./interfaces/token/IWETH.sol";

/// @title Plexus Core Contract
/// @author Team Plexus
/// @notice Mainnet address - 0x7a72b2C51670a3D77d425C2DB90F6ddb09E4303
contract Core is OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Global state variables
    address public oracleAddress;
    address public converterAddress;
    address public stakingAddress;
    address public ETH_TOKEN_ADDRESS;
    address public WETH_TOKEN_ADDRESS;
    uint256 private approvalAmount;
    IPlexusOracle private oracle;
    ITier1Staking private staking;
    IConverter private converter;
    IWETH private wethToken;

    constructor() payable {
    }

    /**
     * @notice Executed on a call to the contract if none of the other
     * functions match the given function signature, or if no data was
     * supplied at all and there is no receive Ether function
     * @dev For the converter to unwrap ETH when delegate calling. The
     * contract has to be able to accept ETH for this reason. The emergency
     * withdrawal call is to pick any change up for these conversions
     */
    fallback() external payable { }

    /**
     * @notice Function executed on plain ether transfers and on a call to the
     * contract with empty calldata
     */
    receive() external payable { }

    /**
     * @notice Modifier check to ensure that a function is executed only if it
     * was called with a non-zero amount value
     * @param amount Amount value
     */
    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    /**
     * @notice Initialize the core contract
     * @param _weth Address to the WETH token contract
     * @param _converter Address to the converter contract
     */
    function initialize(address _weth, address _converter) external initializeOnceOnly {
        ETH_TOKEN_ADDRESS = address(0x0);
        WETH_TOKEN_ADDRESS = _weth;
        wethToken = IWETH(WETH_TOKEN_ADDRESS);
        approvalAmount = 1000000000000000000000000000000;
        setConverterAddress(_converter);
    }

    /**
     * @notice Set the oracle contract address
     * @param theAddress Oracle contract address
     */
    function setOracleAddress(address theAddress) external onlyOwner returns (bool) {
        oracleAddress = theAddress;
        oracle = IPlexusOracle(theAddress);
        return true;
    }

    /**
     * @notice Set the Tier1 staking contract address
     * @param theAddress Tier 1 staking contract address
     */
    function setStakingAddress(address theAddress) external onlyOwner returns (bool) {
        stakingAddress = theAddress;
        staking = ITier1Staking(theAddress);
        return true;
    }

    /**
     * @notice Deposit assets via a given Tier 2 staking contract
     * @param tier2ContractName Tier 2 contract used to deposit assets
     * @param tokenAddress Token address for the asset to be withdrawn
     * @param amount Quantity of specified token to be deposited
     */
    function deposit(
        string memory tier2ContractName,
        address tokenAddress,
        uint256 amount
    )
        external
        payable
        nonReentrant
        nonZeroAmount(amount)
        returns (bool)
    {
        IERC20 token;
        if (tokenAddress == ETH_TOKEN_ADDRESS) {
            wethToken.deposit{value: msg.value}();
            tokenAddress = WETH_TOKEN_ADDRESS;
            token = IERC20(tokenAddress);
        } else {
            token = IERC20(tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        token.safeIncreaseAllowance(stakingAddress, 0);
        token.safeIncreaseAllowance(stakingAddress, approvalAmount);
        bool result = staking.deposit(tier2ContractName, tokenAddress, amount, msg.sender);
        require(result, "There was an issue in core with your deposit request.");
        return result;
    }

    /**
     * @notice Withdraw assets from a given Tier 2 staking contract
     * @param tier2ContractName Tier 2 contract used to withdraw assets
     * @param tokenAddress Token address for the asset to be withdrawn
     * @param amount Quantity of specified token to be withdrawn
     */
    function withdraw(
        string memory tier2ContractName,
        address tokenAddress,
        uint256 amount
    )
        external
        payable
        nonReentrant
        nonZeroAmount(amount)
        returns (bool)
    {
        bool result = staking.withdraw(tier2ContractName, tokenAddress, amount, msg.sender);
        require(result, "There was an issue in core with your withdrawal request.");
        return result;
    }

    /**
     * @notice Convert a provided source token to multiple output tokens
     * @dev Converting is mostly for removing liquidity from LP tokens by
     * swapping them for their underlying assets
     * @param sourceToken Address to provided source LP tokens
     * @param destinationTokens Address list for output destination tokens
     * @param paths Paths for uniswap
     * @param amount Amount of provided LP tokens to be converted
     * @param userSlippageTolerance Maximum slippage tolerance limit
     * @return Output tokens acquired by swapping provided source tokens
     */
    function convert(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        external
        payable
        nonZeroAmount(amount)
        returns (address, uint256)
    {
        if (sourceToken != ETH_TOKEN_ADDRESS) {
            IERC20 srcToken = IERC20(sourceToken);
            srcToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        (
            address destinationTokenAddress,
            uint256 _amount
        ) = converter.wrap{
                value: msg.value
            }(sourceToken, destinationTokens, paths, amount, userSlippageTolerance, deadline);

        IERC20 dstToken = IERC20(destinationTokenAddress);
        dstToken.safeTransfer(msg.sender, _amount);
        return (destinationTokenAddress, _amount);
    }

    /**
     * @notice Convert provided LP tokens to a common output token
     * @dev De-converting is mostly for LP tokens back to another token, as
     * these cant be simply swapped on uniswap
     * @param sourceToken Address to provided source LP tokens
     * @param destinationToken Address to desired output destination tokens
     * @param paths Paths for uniswap
     * @param lpTokenPairAddress address for lp token
     * @param amount Amount of provided LP tokens to be converted
     * @param userSlippageTolerance Maximum slippage tolerance limit
     * @return Destination tokens acquired by converting provided LP tokens
     */
    function deconvert(
        address sourceToken,
        address destinationToken,
        address lpTokenPairAddress,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        external
        payable
        returns (uint256)
    {
        uint256 _amount =
            converter.unwrap{value: msg.value}(
                sourceToken,
                destinationToken,
                lpTokenPairAddress,
                paths,
                amount,
                userSlippageTolerance,
                deadline
            );
        IERC20 token = IERC20(destinationToken);
        token.safeTransfer(msg.sender, _amount);
        return _amount;
    }

    /**
     * @notice Retrieve details about all tokens that can be staked
     * @return Two arrays - one containing a list of addresses to all tokens
     * that can be staked and another containing their respective token names
     */
    function getStakableTokens() external view returns (address[] memory, string[] memory) {
        (
            address[] memory stakableAddresses,
            string[] memory stakableTokenNames
        ) = oracle.getStakableTokens();
        return (stakableAddresses, stakableTokenNames);
    }

    /**
     * @notice Retrieve the APR yield for a given token from a specified
     * Tier 2 contract
     * @param tier2Address Address to the specified Tier 2 contract
     * @param tokenAddress Address to the given token for which the APR
     * yield is to be retrieved
     * @return APR yield for the given token address from the specified Tier 2
     * contract
     */
    function getAPR(address tier2Address, address tokenAddress) external view returns (uint256) {
        uint256 result = oracle.getAPR(tier2Address, tokenAddress);
        return result;
    }

    function getTotalValueLockedAggregated(uint256 optionIndex) external view returns (uint256) {
        uint256 result = oracle.getTotalValueLockedAggregated(optionIndex);
        return result;
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
        uint256 result = oracle.getTotalValueLockedInternalByToken(tokenAddress, tier2Address);
        return result;
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
        uint256 result = oracle.getAmountStakedByUser(tokenAddress, userAddress, tier2Address);
        return result;
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
        return oracle.getUserCurrentReward( userAddress, tokenAddress, tier2FarmAddress);
    }

    /**
     * @notice Retrieve the current price of a token
     * @param tokenAddress Address to the token for which the price is to be
     * retrieved
     * @return Current price of the specified token
     */
    function getTokenPrice(address tokenAddress) external view returns (uint256) {
        uint256 result = oracle.getTokenPrice(tokenAddress);
        return result;
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
        uint256 result = oracle.getUserWalletBalance(userAddress, tokenAddress);
        return result;
    }

    /**
     * @notice Update the WETH token contract address
     * @param newAddress New WETH contract address to be updated
     */
    function updateWETHAddress(address newAddress) external onlyOwner returns (bool) {
        WETH_TOKEN_ADDRESS = newAddress;
        wethToken = IWETH(newAddress);
        return true;
    }

    /**
    * @notice Function allowing admins to revert accidentally deposited tokens
    * @param token Address to the token to be withdrawn
    * @param amount Amount of specified token to be withdrawn
    * @param destination Address where the withdrawn tokens should be
    * transferred
    */
    function adminEmergencyWithdrawAccidentallyDepositedTokens(
        address token,
        uint256 amount,
        address payable destination
    ) public onlyOwner returns (bool) {
        if (address(token) == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }

        return true;
    }

    /**
     * @notice Set converter contract address
     * @param theAddress Converter contract address
     */
    function setConverterAddress(address theAddress) public onlyOwner returns (bool) {
        converterAddress = theAddress;
        converter = IConverter(theAddress);
        return true;
    }
}
