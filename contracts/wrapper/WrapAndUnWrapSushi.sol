// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../proxyLib/OwnableUpgradeable.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/sushiswap/ISushiV2.sol";
import "../interfaces/sushiswap/ISushiSwapFactory.sol";

/// @title Plexus LP Wrapper Contract - SushiSwap
/// @author Team Plexus
contract WrapAndUnWrapSushi is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract state variables
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    bool public changeRecpientIsOwner;
    address private sushiAddress;
    address private sushiFactoryAddress;
    uint256 public fee;
    uint256 public maxfee;
    mapping(address => address[]) public lpTokenAddressToPairs;
    mapping(string => address) public stablecoins;
    mapping(address => mapping(address => address[])) public presetPaths;
    event WrapSushi(address lpTokenPairAddress, uint256 amount);
    event UnWrapSushi(uint256 amount);
    event RemixUnwrap(uint256 amount);
    event RemixWrap(address lpTokenPairAddress, uint256 amount);
    ISushiV2 private sushiExchange;
    ISushiSwapFactory private factory;

    constructor() payable {}

    /**
     * @notice Initialize the Sushi Wrapper contract
     * @param _weth Address to the WETH token contract
     * @param _sushiAddress Address to the SushiSwap contract
     * @param _sushiFactoryAddress Address to the SushiV2 factory contract
     */
    function initialize(
        address _weth,
        address _sushiAddress,
        address _sushiFactoryAddress
    )
        public
        initializeOnceOnly
    {
        WETH_TOKEN_ADDRESS = _weth;
        sushiAddress = _sushiAddress;
        sushiExchange = ISushiV2(sushiAddress);
        sushiFactoryAddress = _sushiFactoryAddress;
        factory = ISushiSwapFactory(sushiFactoryAddress);
        fee = 0;
        maxfee = 0;
        changeRecpientIsOwner = false;
    }

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
     * @notice Executed on a call to the contract if none of the other
     * functions match the given function signature, or if no data was
     * supplied at all and there is no receive Ether function
     */
    fallback() external payable {}

     /**
     * @notice Function executed on plain ether transfers and on a call to the
     * contract with empty calldata
     */
    receive() external payable {}

    /**
     * @notice Allow owner to collect a small fee from trade imbalances on
     * LP conversions
     * @param changeRecpientIsOwnerBool If set to true, allows owner to collect
     * fees from pair imbalances
     */
    function updateChangeRecipientBool(bool changeRecpientIsOwnerBool)
        external
        onlyOwner
        returns (bool)
    {
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }

    /**
     * @notice Update the SushiSwap exchange contract address
     * @param newAddress SushiSwap exchange contract address to be updated
     */
    function updateSushiExchange(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        sushiExchange = ISushiV2(newAddress);
        sushiAddress = newAddress;
        return true;
    }

     /**
     * @notice Update the Uniswap factory contract address
     * @param newAddress Uniswap factory contract address to be updated
     */
    function updateSushiSwapFactory(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        factory = ISushiSwapFactory(newAddress);
        sushiFactoryAddress = newAddress;
        return true;
    }

    /**
     * @notice Retrieve the LP token address for a given pair of tokens
     * @param token1 Address to the first token in the LP pair
     * @param token2 Address to the second token in the LP pair
     * @return lpAddr Address to the LP token contract composed of the given
     * token pair
     */
    function getLPTokenByPair(
        address token1,
        address token2
    )
        external
        view
        returns (address lpAddr)
    {
        address thisPairAddress = factory.getPair(token1, token2);
        return thisPairAddress;
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
    * @notice Allow admins to withdraw accidentally deposited tokens
    * @param token Address to the token to be withdrawn
    * @param amount Amount of specified token to be withdrawn
    * @param destination Address where the withdrawn tokens should be
    * transferred
    */
    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    )
        public
        onlyOwner
        returns (bool)
    {
        if (address(token) == address(0x0)) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }
        return true;
    }

    /**
     * @notice Update the protocol fee rate
     * @param newFee Updated fee rate to be charged
     */
    function setFee(uint256 newFee) public onlyOwner returns (bool) {
        require(
            newFee <= maxfee,
            "Admin cannot set the fee higher than the current maxfee"
        );
        fee = newFee;
        return true;
    }

     /**
     * @notice Set the max protocol fee rate
     * @param newMax Updated maximum fee rate value
     */
    function setMaxFee(uint256 newMax) public onlyOwner returns (bool) {
        require(maxfee == 0, "Admin can only set max fee once and it is perm");
        maxfee = newMax;
        return true;
    }

    function swap(
        address sourceToken,
        address destinationToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) private returns (uint256) {
        if (sourceToken != address(0x0)) {
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }
        conductSushiSwap(sourceToken, destinationToken, path, amount, userSlippageTolerance, deadline);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function createWrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool remixing
    ) private returns (address, uint256) {
        if (sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            amount = msg.value;
        } else {
            if(!remixing) { // only transfer when not remixing
                IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
            }
            
        }

        if (destinationTokens[0] == address(0x0)) {
            destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (destinationTokens[1] == address(0x0)) {
            destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (sourceToken != destinationTokens[0]) {
            conductSushiSwap(
                sourceToken,
                destinationTokens[0],
                paths[0],
                amount.div(2),
                userSlippageTolerance,
                deadline
            );
        }
        if (sourceToken != destinationTokens[1]) {
             conductSushiSwap(
                sourceToken,
                destinationTokens[1],
                paths[1],
                amount.div(2),
                userSlippageTolerance,
                deadline
            );
        }

        IERC20 dToken1 = IERC20(destinationTokens[0]);
        IERC20 dToken2 = IERC20(destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken1.allowance(address(this), sushiAddress) < dTokenBalance1.mul(2)) {
            dToken1.safeIncreaseAllowance(sushiAddress, dTokenBalance1.mul(3));
        }

        if (dToken2.allowance(address(this), sushiAddress) < dTokenBalance2.mul(2)) {
            dToken2.safeIncreaseAllowance(sushiAddress, dTokenBalance2.mul(3));
        }

        sushiExchange.addLiquidity(
            destinationTokens[0],
            destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress =
            factory.getPair(destinationTokens[0], destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        if (fee > 0) {
            uint256 totalFee = (thisBalance.mul(fee)).div(10000);
            if (totalFee > 0) {
                lpToken.safeTransfer(owner(), totalFee);
            }
            thisBalance = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(msg.sender, thisBalance);
        } else {
            lpToken.safeTransfer(msg.sender, thisBalance);
        }

        // Transfer any change to changeRecipient
        // (from a pair imbalance. Should never be more than a few basis points)
        address changeRecipient = msg.sender;
        if (changeRecpientIsOwner == true) {
            changeRecipient = owner();
        }
        if (dToken1.balanceOf(address(this)) > 0) {
            dToken1.safeTransfer(changeRecipient, dToken1.balanceOf(address(this)));
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(changeRecipient, dToken2.balanceOf(address(this)));
        }
        return (thisPairAddress, thisBalance);
    }

    /**
     * @notice Wrap a source token based on the specified
     * destination token(s)
     * @param sourceToken Address to the source token contract
     * @param destinationTokens Array describing the token(s) which the source
     * @param paths Paths for uniswap
     * token will be wrapped into
     * @param amount Amount of source token to be wrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (address, uint256)
    {
        if (destinationTokens.length == 1) {
            uint256 swapAmount = swap(sourceToken, destinationTokens[0], paths[0], amount, userSlippageTolerance, deadline);
            return (destinationTokens[0], swapAmount);
        } else {
            bool remixing = false;
            (address lpTokenPairAddress, uint256 lpTokenAmount) = createWrap(sourceToken, destinationTokens, paths, amount, userSlippageTolerance, deadline, remixing);
            emit WrapSushi(lpTokenPairAddress, lpTokenAmount);
            return (lpTokenPairAddress, lpTokenAmount);
        }
    }

    function removeWrap(
        address sourceToken,
        address destinationToken,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool remixing
    )
        private
        returns (uint256)
    {
        address originalDestinationToken = destinationToken;
      
        IERC20 sToken = IERC20(sourceToken);
        if (destinationToken == address(0x0)) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (sourceToken != address(0x0)) {
            sToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(sourceToken);
        address token0 = thisLpInfo.token0();
        address token1 = thisLpInfo.token1();

        if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
            sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
        }

        sushiExchange.removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            address(this),
            1000000000000000000000000000
        );

        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));

        if (token0 != destinationToken) {
            conductSushiSwap(
                token0,
                destinationToken,
                paths[0],
                pTokenBalance,
                userSlippageTolerance,
                deadline
            );
        }

        if (token1 != destinationToken) {
            conductSushiSwap(
                token1,
                destinationToken,
                paths[1],
                pTokenBalance2,
                userSlippageTolerance,
                deadline
            );
        }

        IERC20 dToken = IERC20(destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));
    
        if (remixing) {
            
            emit RemixUnwrap(destinationTokenBalance);
        }
        else { // we only transfer the tokens to the user when not remixing
            if (originalDestinationToken == address(0x0)) {
                IWETH(WETH_TOKEN_ADDRESS).withdraw(destinationTokenBalance);
                if (fee > 0) {
                    uint256 totalFee = (address(this).balance.mul(fee)).div(10000);
                    if (totalFee > 0) {
                        payable(owner()).transfer(totalFee);
                    }
                        payable(msg.sender).transfer(address(this).balance);
                } else {
                    payable(msg.sender).transfer(address(this).balance);
                }
            } else {
                if (fee > 0) {
                    uint256 totalFee = (destinationTokenBalance.mul(fee)).div(10000);
                    if (totalFee > 0) {
                        dToken.safeTransfer(owner(), totalFee);
                    }
                    destinationTokenBalance = dToken.balanceOf(address(this));
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                } else {
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                }
            }

        }
       
        return destinationTokenBalance;
    }

    /**
     * @notice Unwrap a source token based to the specified destination token
     * @param sourceToken Address to the source token contract
     * @param destinationToken Address to the destination token contract
     * @param paths Paths for uniswap
     * @param lpTokenPairAddress address for lp token
     * @param amount Amount of source token to be unwrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        address sourceToken,
        address destinationToken,
        address lpTokenPairAddress,
        address[][] calldata paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {

        if (lpTokenPairAddress == address(0x0)) {
            return swap(sourceToken, destinationToken, paths[0], amount, userSlippageTolerance, deadline);
        } else {
            bool remixing = false; //flag indicates whether we're remixing or not
            uint256 destAmount = removeWrap(lpTokenPairAddress, destinationToken, paths, amount, userSlippageTolerance, deadline, remixing);
            emit UnWrapSushi(destAmount);
            return destAmount;
        }
    }

     /**
     * @notice Unwrap a source token and wrap it into a different destination token 
     * @param lpTokenPairAddress Address for the LP pair to remix
     * @param unwrapOutputToken Address for the initial output token of remix
     * @param destinationTokens Address to the destination tokens to be remixed to
     * @param unwrapPaths Paths best sushi trade paths for doing the unwrapping
     * @param wrapPaths Paths best sushi trade paths for doing the wrapping to the new LP token
     * @param amount Amount of LP Token to be remixed
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source LP token
     */
    function remix(
        address lpTokenPairAddress,
        address unwrapOutputToken,
        address[] memory destinationTokens,
        address[][] calldata unwrapPaths,
        address[][] calldata wrapPaths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {
        bool remixing = true; //flag indicates whether we're remixing or not
        uint256 destAmount = removeWrap(lpTokenPairAddress, unwrapOutputToken, unwrapPaths, amount, userSlippageTolerance, deadline, remixing);

        IERC20 dToken = IERC20(unwrapOutputToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

        require(destAmount == destinationTokenBalance, "Error: Remix output balance not correct");
       
        // then now we create the new LP token
        address outputToken = unwrapOutputToken;
        address [] memory dTokens = destinationTokens;
        address [][] calldata paths = wrapPaths;
        uint256 slippageTolerance = userSlippageTolerance;
        uint256 timeout = deadline;
        bool remixingToken = true; //flag indicates whether we're remixing or not

        (address remixedLpTokenPairAddress, uint256 lpTokenAmount) = createWrap(outputToken, dTokens, paths, destinationTokenBalance, slippageTolerance, timeout, remixingToken);
                                                                
        emit RemixWrap(remixedLpTokenPairAddress, lpTokenAmount);
        return lpTokenAmount;
        
    }


    /**
     * @notice Given an input asset amount and an array of token addresses,
     * calculates all subsequent maximum output token amounts for each pair of
     * token addresses in the path using SushiSwap
     * @param theAddresses Array of addresses that form the Routing swap path
     * @param amount Amount of input asset token
     * @return amounts1 Array with maximum output token amounts for all token
     * pairs in the swap path
     */
    function getPriceFromSushiswap(
        address[] memory theAddresses,
        uint256 amount
    )
        public
        view
        returns (uint256[] memory amounts1)
    {
        try sushiExchange.getAmountsOut(
            amount,
            theAddresses
        ) returns (uint256[] memory amounts) {
            return amounts;
        } catch {
            uint256[] memory amounts2 = new uint256[](2);
            amounts2[0] = 0;
            amounts2[1] = 0;
            return amounts2;
        }
    }

    /**
     * @notice Retrieve minimum output amount required based on uniswap routing
     * path and maximum permissible slippage
     * @param theAddresses Array list describing the SushiSwap swap path
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Minimum amount of output tokens the input token can be swapped
     * for, based on the Uniswap prices and Slippage tolerance thresholds
     */
    function getAmountOutMin(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    )
        public
        view
        returns (uint256)
    {
        uint256[] memory assetAmounts = getPriceFromSushiswap(
            theAddresses,
            amount
        );
        require(
            userSlippageTolerance <= 100,
            "userSlippageTolerance can not be larger than 100"
        );

          // this is the index of the output token we're swapping to based on the paths
        uint outputTokenIndex = assetAmounts.length - 1;
        return
            SafeMath.div(
                SafeMath.mul(assetAmounts[outputTokenIndex], (100 - userSlippageTolerance)),
                100
            );
    }

     /**
     * @notice Perform a SushiSwap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param userSlippageTolerance Maximum permissible slippage limit
     * @return amounts1 Tokens received once the swap is completed
     */
    function conductSushiSwap(
        address sellToken,
        address buyToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256 amounts1)
    {
        if (sellToken == address(0x0) && buyToken == WETH_TOKEN_ADDRESS) {
            IWETH(buyToken).deposit{value: msg.value}();
            return amount;
        }

        if (sellToken == address(0x0)) {
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(path, amount, userSlippageTolerance);
            sushiExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }

            uint256[] memory amounts = conductSushiSwapT4T(
                path,
                amount,
                userSlippageTolerance,
                deadline
            );
            uint256 resultingTokens = amounts[amounts.length - 1];
            return resultingTokens;
        }
    }

    /**
     * @notice Using SushiSwap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param theAddresses Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible slippage tolerance
     * @return amounts1 The input token amount and all subsequent output token
     * amounts
     */
    function conductSushiSwapT4T(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts1)
    {
        uint256 amountOutMin = getAmountOutMin(
            theAddresses,
            amount,
            userSlippageTolerance
        );
        uint256[] memory amounts = sushiExchange.swapExactTokensForTokens(
            amount,
            amountOutMin,
            theAddresses,
            address(this),
            deadline
        );
        return amounts;
    }
}