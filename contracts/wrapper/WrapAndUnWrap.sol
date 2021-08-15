// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/uniswap/IUniswapV2.sol";
import "../interfaces/uniswap/IUniswapFactory.sol";
import "../interfaces/IRemix.sol";

/// @title Plexus LP Wrapper Contract
/// @author Team Plexus
contract WrapAndUnWrap  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract state variables
    bool public changeRecpientIsOwner;
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    address private uniAddress;
    address private uniFactoryAddress;
    address public owner;
    address public wrapperSushiAddress;
    uint256 public fee;
    uint256 public maxfee;
    IUniswapV2 private uniswapExchange;
    IUniswapFactory private factory;

    // events
    event WrapV2(address lpTokenPairAddress, uint256 amount);
    event UnWrapV2(uint256 amount);
    event RemixUnwrap(uint256 amount);
    event RemixWrap(address lpTokenPairAddress, uint256 amount);


    constructor(
        address _weth,
        address _uniAddress,
        address _uniFactoryAddress
    )
        payable
    {
        WETH_TOKEN_ADDRESS = _weth;
        uniAddress = _uniAddress;
        uniswapExchange = IUniswapV2(uniAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapFactory(uniFactoryAddress);
        fee = 0;
        maxfee = 0;
        changeRecpientIsOwner = false;
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Not contract owner!");
      _;
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
     * @notice Set the WrapperSushi contract address
     * @param newAddress WrapperSushi contract address to be updated
     */
    function setWrapperSushiAddress(address newAddress) external onlyOwner returns (bool) {
        wrapperSushiAddress = newAddress;
        return true;
    }


    /**
     * @notice Allow owner to collect a small fee from trade imbalances on
     * LP conversions
     * @param changeRecpientIsOwnerBool If set to true, allows owner to collect
     * fees from pair imbalances
     */
    function updateChangeRecipientBool(
        bool changeRecpientIsOwnerBool
    )
        external
        onlyOwner
        returns (bool)
    {
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }

    /**
     * @notice Update the Uniswap exchange contract address
     * @param newAddress Uniswap exchange contract address to be updated
     */
    function updateUniswapExchange(address newAddress) external onlyOwner returns (bool) {
        uniswapExchange = IUniswapV2(newAddress);
        uniAddress = newAddress;
        return true;
    }

    /**
     * @notice Update the Uniswap factory contract address
     * @param newAddress Uniswap factory contract address to be updated
     */
    function updateUniswapFactory(address newAddress) external onlyOwner returns (bool) {
        factory = IUniswapFactory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
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

        conductUniswap(sourceToken, destinationToken, path, amount, userSlippageTolerance, deadline);
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
    ) public payable returns (address, uint256) {
        if (sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            amount = msg.value;
        } else {
            
            if(!remixing) { // only transfer when not remixing, because when remixing the amount should already be sent to the contract
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
            conductUniswap(
                sourceToken,
                destinationTokens[0],
                paths[0],
                amount.div(2),
                userSlippageTolerance,
                deadline
            );
        }
        if (sourceToken != destinationTokens[1]) {
            conductUniswap(
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

        if (dToken1.allowance(address(this), uniAddress) < dTokenBalance1.mul(2)) {
            dToken1.safeIncreaseAllowance(uniAddress, dTokenBalance1.mul(3));
        }

        if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2.mul(2)) {
            dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2.mul(3));
        }

        uniswapExchange.addLiquidity(
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
                lpToken.safeTransfer(owner, totalFee);
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
            changeRecipient = owner;
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
            emit WrapV2(lpTokenPairAddress, lpTokenAmount);
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

        if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
            sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
        }

        uniswapExchange.removeLiquidity(
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
            conductUniswap(
                token0,
                destinationToken,
                paths[0],
                pTokenBalance,
                userSlippageTolerance,
                deadline
            );
        }

        if (token1 != destinationToken) {
            conductUniswap(
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
                        payable(owner).transfer(totalFee);
                    }
                        payable(msg.sender).transfer(address(this).balance);
                } else {
                    payable(msg.sender).transfer(address(this).balance);
                }
            } else {
                if (fee > 0) {
                    uint256 totalFee = (destinationTokenBalance.mul(fee)).div(10000);
                    if (totalFee > 0) {
                        dToken.safeTransfer(owner, totalFee);
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
     * @param lpTokenPairAddress address for lp token
     * @param destinationToken Address of the destination token contract
     * @param paths Paths for uniswap
     * @param amount Amount of source token to be unwrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        address lpTokenPairAddress,
        address destinationToken,
        address[][] calldata paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {

      
        bool remixing = false; //flag indicates whether we're remixing or not
        uint256 destAmount = removeWrap(lpTokenPairAddress, destinationToken, paths, amount, userSlippageTolerance, deadline, remixing);
        emit UnWrapV2(destAmount);
        return destAmount;
    
    }

     /**
     * @notice Unwrap a source token and wrap it into a different destination token 
     * @param lpTokenPairAddress Address for the LP pair to remix
     * @param unwrapOutputToken Address for the initial output token of remix
     * @param destinationTokens Address to the destination tokens to be remixed to
     * @param unwrapPaths Paths best uniswap trade paths for doing the unwrapping
     * @param wrapPaths Paths best uniswap trade paths for doing the wrapping to the new LP token
     * @param amount Amount of LP Token to be remixed
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @param deadline Timeout after which the txn should revert
     * @param crossDexRemix Indicates whether this is a cross-dex remix or not
     * @return Amount of the destination token returned from unwrapping the
     * source LP token
     */
    function remix(
        address lpTokenPairAddress,
        address unwrapOutputToken,
        address[] memory destinationTokens,
        address[][] memory unwrapPaths,
        address[][] memory wrapPaths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool crossDexRemix
    )
        public
        payable
        returns (uint256)
    {
        uint lpTokenAmount = 0;

        // First of all we unwrap the token
        uint256 destinationTokenBalance = removeWrap(lpTokenPairAddress, unwrapOutputToken, unwrapPaths, amount, userSlippageTolerance, deadline, true);

        if(crossDexRemix) {

            // send the unwrapped token to sushi for remixing
            IERC20(unwrapOutputToken).safeTransfer(wrapperSushiAddress, destinationTokenBalance);

            // then do the remix
            (address remixedLpTokenPairAddress, uint256 remixedLpTokenAmount) = IRemix(wrapperSushiAddress)
                .createWrap(unwrapOutputToken, destinationTokens, wrapPaths, destinationTokenBalance, userSlippageTolerance, deadline, true);  
            lpTokenAmount = remixedLpTokenAmount;
            // transfer the remixed lp token back to the user
            IERC20(remixedLpTokenPairAddress).safeTransfer(msg.sender, lpTokenAmount);

            emit RemixWrap(remixedLpTokenPairAddress, lpTokenAmount);
                                   
        } else {
            // then now we create the new LP token
            (address remixedLpTokenPairAddress, uint256 remixedLpTokenAmount) = createWrap(unwrapOutputToken, destinationTokens, 
                wrapPaths, destinationTokenBalance, userSlippageTolerance, deadline, true);
            
            lpTokenAmount = remixedLpTokenAmount;

            emit RemixWrap(remixedLpTokenPairAddress, remixedLpTokenAmount);
        }

        return lpTokenAmount;
        
    }


    /**
     * @notice Given an input asset amount and an array of token addresses,
     * calculates all subsequent maximum output token amounts for each pair of
     * token addresses in the path.
     * @param theAddresses Array of addresses that form the Routing swap path
     * @param amount Amount of input asset token
     * @return amounts1 Array with maximum output token amounts for all token
     * pairs in the swap path
     */
    function getPriceFromUniswap(address[] memory theAddresses, uint256 amount)
        public
        view
        returns (uint256[] memory amounts1) {
        try uniswapExchange.getAmountsOut(
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
        public
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
        public
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    /**
     * @notice Retrieve minimum output amount required based on uniswap routing
     * path and maximum permissible slippage
     * @param paths Array list describing the Uniswap router swap path
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Minimum amount of output tokens the input token can be swapped
     * for, based on the Uniswap prices and Slippage tolerance thresholds
     */
    function getAmountOutMin(
        address[] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance
    )
        public
        view
        returns (uint256)
    {
        uint256[] memory assetAmounts = getPriceFromUniswap(paths, amount);
        

        // this is the index of the output token we're swapping to based on the paths
        uint outputTokenIndex = assetAmounts.length - 1;
        require(userSlippageTolerance <= 100, "userSlippageTolerance can not be larger than 100");
        return SafeMath.div(SafeMath.mul(assetAmounts[outputTokenIndex], (100 - userSlippageTolerance)), 100);
    }

    /**
     * @notice Perform a Uniswap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param path Path for uniswap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param userSlippageTolerance Maximum permissible slippage limit
     * @return amounts1 Tokens received once the swap is completed
     */
    function conductUniswap(
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
            uniswapExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
            }

            uint256[] memory amounts = conductUniswapT4T(
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
     * @notice Using Uniswap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param paths Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible slippage tolerance
     * @return amounts_ The input token amount and all subsequent output token
     * amounts
     */
    function conductUniswapT4T(
        address[] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts_)
    {
        uint256 amountOutMin = getAmountOutMin(paths, amount, userSlippageTolerance);
        uint256[] memory amounts =
            uniswapExchange.swapExactTokensForTokens(
                amount,
                amountOutMin,
                paths,
                address(this),
                deadline
            );
        return amounts;
    }
}