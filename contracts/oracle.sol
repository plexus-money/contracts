// SPDX-License-Identifier: MIT

/**
_____  _
|  __ \| |
| |__) | | _____  ___   _ ___
|  ___/| |/ _ \ \/ / | | / __|
| |    | |  __/>  <| |_| \__ \
|_|   _|_|\___/_/\_\\__,_|___/ 
 *Submitted for verification at Etherscan.io on 2020-12-11
*/

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/IExternalPlatform.sol";
import "./interfaces/staking/ITokenRewards.sol";
import "./interfaces/ITVLOracle.sol";

interface IUniswapV2RouterLite {
    function getAmountsOut(uint amountIn, address[] memory  path) external view returns (uint[] memory amounts);
}

contract PlexusOracle is OwnableUpgradeable {
    using SafeMath for uint256;
  //  address payable public owner;
    address private burnaddress;
    mapping (string => address) private farmDirectoryByName;
    mapping (address => mapping(address =>uint256)) private farmManuallyEnteredAPYs;
    mapping (address => mapping (address  => address )) private farmOracleObtainedAPYs;
    string [] public farmTokenPlusFarmNames;
    address [] public farmAddresses;
    address [] public farmTokens;
    address uniswapAddress;
    IUniswapV2RouterLite private uniswap;
    address private usdcCoinAddress;
    address public rewardAddress;
    ITokenRewards private reward;
    address private tvlOracleAddress;
    ITVLOracle private tvlOracle;
    //core contract adress that users interact with
    address public coreAddress;
    address public tier1Address;
    mapping (string  => address) public platformDirectory;

    constructor() payable {
    }

    function initialize(address _uniswap, address _usdc) initializeOnceOnly public {
        burnaddress  = address(0x0);
        uniswapAddress = _uniswap;
        uniswap = IUniswapV2RouterLite(uniswapAddress);
        usdcCoinAddress = _usdc;
    }

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

    function getStakableTokens() external view returns (address[] memory, string[] memory) {
        address[] memory stakableAddrs = farmAddresses;
        string[] memory stakableNames = farmTokenPlusFarmNames;
        return (stakableAddrs, stakableNames);
    }

    function getAPR(address farmAddress, address farmToken) public view returns (uint256) {
        uint256 obtainedAPY = farmManuallyEnteredAPYs[farmAddress][farmToken];

        if (obtainedAPY == 0) {
            IExternalPlatform exContract = IExternalPlatform(farmOracleObtainedAPYs[farmAddress][farmToken]);
            try exContract.getAPR(farmAddress, farmToken) returns (uint256 apy) {
                return apy;
            } catch (bytes memory) {
                return (0);
            }
        } else {
            return obtainedAPY;
        }
    }

    function getAmountStakedByUser(
        address tokenAddress,
        address userAddress,
        address tier2Address
    ) external view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(tier2Address);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

    function getUserCurrentReward(
        address userAddress,
        address tokenAddress,
        address tier2FarmAddress
    ) external view returns (uint256) {
        uint256 userStartTime = reward.depositBalancesDelegated(userAddress, tokenAddress, 0);

        uint256 principalAmount = reward.depositBalancesDelegated(userAddress, tokenAddress, 1);
        uint256 apr = reward.tokenAPRs(tokenAddress);
        uint256 result = reward.calculateRewards(userStartTime, block.timestamp, principalAmount, apr);
        return result;
    }

    function getTokenPrice(address tokenAddress, uint256 amount) external view returns (uint256) {
        address[] memory addresses = new address[](2);
        addresses[0] = tokenAddress;
        addresses[1] = usdcCoinAddress;
        uint256[] memory amounts = getUniswapPrice(addresses, amount);
        uint256 resultingTokens = amounts[1];
        return resultingTokens;
    }

    function getUserWalletBalance(address userAddress, address tokenAddress) external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    function getAddress(string memory component) public view returns (address) {
        return platformDirectory[component];
    }

    // BELOW is other (admin and otherwise)

    function updateTVLAddress(address theAddress) public onlyOwner returns (bool) {
        tvlOracleAddress = theAddress;
        tvlOracle = ITVLOracle(theAddress);
        updateDirectory("TVLORACLE", theAddress);
        return true;
    }

    function updatePriceOracleAddress(address theAddress) public onlyOwner returns (bool) {
        uniswapAddress = theAddress;
        uniswap = IUniswapV2RouterLite(theAddress);
        updateDirectory("UNISWAP", theAddress);
        return true;
    }

    function updateUSD(address theAddress) public onlyOwner returns (bool) {
        usdcCoinAddress = theAddress;
        updateDirectory("USD", theAddress);
        return true;
    }

    function updateRewardAddress(address theAddress) public onlyOwner returns (bool) {
        rewardAddress = theAddress;
        reward = ITokenRewards(theAddress);
        updateDirectory("REWARDS", theAddress);
        return true;
    }

    function updateCoreAddress(address theAddress) public onlyOwner returns (bool) {
        coreAddress = theAddress;
        updateDirectory("CORE", theAddress);
        return true;
    }

    function updateTier1Address(address theAddress) public onlyOwner returns (bool) {
        tier1Address = theAddress;
        updateDirectory("TIER1", theAddress);
        return true;
    }

    function updateDirectory(string memory name, address theAddress) public onlyOwner returns (bool) {
        platformDirectory[name] = theAddress;
        return true;
    }

    function setPlatformContract(
        string memory name,
        address farmAddress,
        address farmToken,
        address platformAddress
    ) public onlyOwner returns (bool) {
        farmTokenPlusFarmNames.push(name);
        farmAddresses.push(farmAddress);
        farmTokens.push(farmToken);

        farmOracleObtainedAPYs[farmAddress][farmToken] = platformAddress;
        farmDirectoryByName[name] = platformAddress;

        return true;
    }

    function calculateCommission(uint256 amount, uint256 commission) public pure returns (uint256) {
        uint256 commissionForDAO = (amount.mul(1000).mul(commission)).div(10000000);
        return commissionForDAO;
    }

    function getCommissionByContract(address platformContract) public view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.commission();
    }

    function getTotalStakedByContract(
        address platformContract,
        address tokenAddress
    ) public view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.totalAmountStaked(tokenAddress);
    }

    function getAmountCurrentlyDepositedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) public view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.depositBalances(userAddress, tokenAddress);
    }

    function replaceAllStakableDirectory(
        string[] memory theNames,
        address[] memory theFarmAddresses,
        address[] memory theFarmTokens
    ) public onlyOwner returns (bool) {
        farmTokenPlusFarmNames = theNames;
        farmAddresses = theFarmAddresses;
        farmTokens = theFarmTokens;
        return true;
    }

    function getAmountCurrentlyFarmStakedByContract(
        address platformContract,
        address tokenAddress,
        address userAddress
    ) public view returns (uint256) {
        IExternalPlatform exContract = IExternalPlatform(platformContract);
        return exContract.getStakedPoolBalanceByUser(userAddress, tokenAddress);
    }

    function getUserTokenBalance(address userAddress, address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    function getUniswapPrice(address[] memory theAddresses, uint256 amount) internal view returns (uint256[] memory amounts1) {
        uint256[] memory amounts = uniswap.getAmountsOut(amount, theAddresses);

        return amounts;
    }
}
