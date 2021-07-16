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

// Core contract on Mainnet: 0x7a72b2C51670a3D77d4205C2DB90F6ddb09E4303

contract Core is OwnableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // globals
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

    fallback() external payable {
        // For the converter to unwrap ETH when delegate calling.
        // The contract has to be able to accept ETH for this reason.
        // The emergency withdrawal call is to pick any change up for these conversions.
    }

    receive() external payable {
        // receive function
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    function initialize(address _weth, address _converter) external initializeOnceOnly {
        ETH_TOKEN_ADDRESS = address(0x0);
        WETH_TOKEN_ADDRESS = _weth;
        wethToken = IWETH(WETH_TOKEN_ADDRESS);
        approvalAmount = 1000000000000000000000000000000;
        setConverterAddress(_converter);
    }

    function setOracleAddress(address theAddress) external onlyOwner returns (bool) {
        oracleAddress = theAddress;
        oracle = IPlexusOracle(theAddress);
        return true;
    }

    function setStakingAddress(address theAddress) external onlyOwner returns (bool) {
        stakingAddress = theAddress;
        staking = ITier1Staking(theAddress);
        return true;
    }

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

    function convert(
        address sourceToken,
        address[] memory destinationTokens,
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
            }(sourceToken, destinationTokens, amount, userSlippageTolerance, deadline);

        IERC20 dstToken = IERC20(destinationTokenAddress);
        dstToken.safeTransfer(msg.sender, _amount);
        return (destinationTokenAddress, _amount);
    }

    // deconverting is mostly for LP tokens back to another token, 
    // as these cant be simply swapped on uniswap
    function deconvert(
        address sourceToken,
        address destinationToken,
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
                amount, 
                userSlippageTolerance,
                deadline
            );
        IERC20 token = IERC20(destinationToken);
        token.safeTransfer(msg.sender, _amount);
        return _amount;
    }

    function getStakableTokens() external view returns (address[] memory, string[] memory) {
        (
            address[] memory stakableAddresses, 
            string[] memory stakableTokenNames
        ) = oracle.getStakableTokens();
        return (stakableAddresses, stakableTokenNames);
    }

    function getAPR(address tier2Address, address tokenAddress) external view returns (uint256) {
        uint256 result = oracle.getAPR(tier2Address, tokenAddress);
        return result;
    }

    function getTotalValueLockedAggregated(uint256 optionIndex) external view returns (uint256) {
        uint256 result = oracle.getTotalValueLockedAggregated(optionIndex);
        return result;
    }

    function getTotalValueLockedInternalByToken(
        address tokenAddress,
        address tier2Address
    ) external view returns (uint256) {
        uint256 result = oracle.getTotalValueLockedInternalByToken(tokenAddress, tier2Address);
        return result;
    }

    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) external view returns (uint256) {
        uint256 result = oracle.getAmountStakedByUser(tokenAddress, userAddress, tier2Address);
        return result;
    }

    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) external view returns (uint256) {
        return oracle.getUserCurrentReward( userAddress, tokenAddress, tier2FarmAddress);
    }

    function getTokenPrice(address tokenAddress) external view returns (uint256) {
        uint256 result = oracle.getTokenPrice(tokenAddress);
        return result;
    }

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

    function updateWETHAddress(address newAddress) external onlyOwner returns (bool) {
        WETH_TOKEN_ADDRESS = newAddress;
        wethToken = IWETH(newAddress);
        return true;
    }

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

    function setConverterAddress(address theAddress) public onlyOwner returns (bool) {
        converterAddress = theAddress;
        converter = IConverter(theAddress);
        return true;
    }
}

