// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../proxyLib/OwnableUpgradeable.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/uniswap/IUniswapV2.sol";
import "../interfaces/uniswap/IUniswapV3Factory.sol";
import "../interfaces/uniswap/IUniswapV3Router.sol";
import "../interfaces/uniswap/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../interfaces/uniswap/IERC721Receiver.sol";

/// @title Plexus LP Wrapper Contract
/// @author Team Plexus
contract WrapAndUnWrap is OwnableUpgradeable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Contract state variables
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    bool public changeRecpientIsOwner;
    address private uniAddress;
    address private uniFactoryAddress;
    uint256 public fee;
    uint256 public maxfee;
    IUniswapV2 private uniswapExchange;
    IUniswapV3Factory private factory;
    ISwapRouter private router;
    INonfungiblePositionManager private positionManager;
    IQuoter private quoter;
    event WrapV2(address lpTokenPairAddress, uint256 amount);
    event UnWrapV2(uint256 amount);

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

    struct ReturnParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }
     struct WrapParams {
        address sourceToken;
        address[] destinationTokens;
        bytes []  paths;
        uint256 amount;
        uint256[] minAmounts;
        uint24 poolFee;
        int24 tickLower;
        int24 tickUpper;  
        uint256 userSlippageTolerance;
        uint256 deadline;
     }

    /**
     * @notice Initialize the Wrapper contract
     * @param _weth Address to the WETH token contract
     * @param _uniAddress Address to the Uniswap V2 router contract
     * @param _uniFactoryAddress Address to the Uniswap factory contract
     */
    function initialize(
        address _weth,
        address _uniAddress,
        address _uniFactoryAddress,
        address _positionManager,
        address _quoter
    )
        public
        initializeOnceOnly
    {
        WETH_TOKEN_ADDRESS = _weth;
        uniAddress = _uniAddress;
        uniswapExchange = IUniswapV2(uniAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapV3Factory(uniFactoryAddress);
        positionManager = INonfungiblePositionManager(_positionManager);
        quoter = IQuoter(_quoter);
        fee = 0;
        maxfee = 0;
        changeRecpientIsOwner = false;
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
        factory = IUniswapV3Factory(newAddress);
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

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // get position information
        return this.onERC721Received.selector;
    }

    function swap(
        address sourceToken,
        address destinationToken,
        bytes memory path,
        uint256 amount,
        uint256 minAmount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) private returns (uint256) {
        if (sourceToken != address(0x0)) {
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        conductUniswap(sourceToken, destinationToken, path, amount, minAmount, userSlippageTolerance, deadline);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function createWrap(
        WrapParams memory params
    ) private returns (uint256, uint128, uint256, uint256) {
        if (params.sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            params.amount = msg.value;
        } else {
            IERC20(params.sourceToken).safeTransferFrom(msg.sender, address(this), params.amount);
        }

        if (params.destinationTokens[0] == address(0x0)) {
            params.destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (params.destinationTokens[1] == address(0x0)) {
            params.destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (params.sourceToken != params.destinationTokens[0]) {
            conductUniswap(
                params.sourceToken,
                params.destinationTokens[0],
                params.paths[0],
                params.amount,
                params.minAmounts[0],
                params.userSlippageTolerance,
                params.deadline
            );
        }
        if (params.sourceToken != params.destinationTokens[1]) {
            conductUniswap(
                params.sourceToken,
                params.destinationTokens[1],
                params.paths[1],
                params.amount,
                params.minAmounts[1],
                params.userSlippageTolerance,
                params.deadline
            );
        }

        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken1.allowance(address(this), uniAddress) < dTokenBalance1.mul(2)) {
            dToken1.safeIncreaseAllowance(uniAddress, dTokenBalance1.mul(3));
        }

        if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2.mul(2)) {
            dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2.mul(3));
        }

        if (fee > 0) {
            uint256 dToken1Balance = dToken1.balanceOf(address(this));
            uint256 halfOfFee1 = (dToken1Balance.mul(fee)).div(10000);
            if (halfOfFee1 > 0) {
                dToken1.safeTransfer(owner(), halfOfFee1);
                dToken1Balance = dToken1Balance.sub(halfOfFee1);
            }
            uint256 dToken2Balance = dToken2.balanceOf(address(this));
            uint256 halfOfFee2 = (dToken2Balance.mul(fee)).div(10000);
            if (halfOfFee2 > 0) {
                dToken2.safeTransfer(owner(), halfOfFee2);
                dToken2Balance = dToken2Balance.sub(halfOfFee2);
            }
        }

        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: params.destinationTokens[0],
                token1: params.destinationTokens[1],
                fee: params.poolFee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: dTokenBalance1,
                amount1Desired: dTokenBalance2,
                amount0Min: params.minAmounts[0],
                amount1Min: params.minAmounts[1],
                recipient: address(this),
                deadline: 1000000000000000000000000000
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = positionManager.mint(params);
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId);

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
        return (tokenId,liquidity,amount0,amount1);
    }

    /**
     * @notice Wrap a source token based on the specified
     * destination token(s)
     * @param sourceToken Address to the source token contract
     * @param destinationTokens Array describing the token(s) which the source
     * @param paths Paths for uniswap
     * token will be wrapped into
     * @param amount Amount of source token to be wrapped
     * @param minAmounts Amount of destination tokens minimum expected
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        bytes [] memory paths,
        uint256 amount,
        uint256[] memory minAmounts,
        uint24 poolFee,
        int24 tickLower,
        int24 tickUpper,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256, uint128, uint256, uint256)
    {
        if (destinationTokens.length == 1) {
            uint256 swapAmount = swap(sourceToken, destinationTokens[0], paths[0], amount, minAmounts[0], userSlippageTolerance, deadline);
            return (0,0,0,swapAmount);
        } else {
            WrapParams memory params = WrapParams({
                sourceToken: sourceToken, 
                destinationTokens : destinationTokens,
                paths: paths,
                amount: amount,
                minAmounts: minAmounts,
                poolFee : poolFee,
                tickLower : tickLower,
                tickUpper : tickUpper,
                userSlippageTolerance : userSlippageTolerance,
                deadline : deadline
            }); 
            (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = createWrap(params);
            //emit WrapV2(lpTokenPairAddress, lpTokenAmount);
            return (tokenId,liquidity,amount0,amount1);
        }
    }

    function removeWrap(
        uint256 tokenId,
        address destinationToken,
        bytes [] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        private
        returns (uint256)
    {
        address originalDestinationToken = destinationToken;

        (
        ,
        ,
        address token0,
        address token1,
        ,
        ,
        ,
        uint128 liquidity,
        ,
        ,
        ,
        ) = positionManager.positions(tokenId);
        if (destinationToken == address(0x0)) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (tokenId != 0) {
            positionManager.safeTransferFrom(msg.sender, address(this), tokenId);
        }
        positionManager.approve(uniAddress, tokenId);

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: 1000000000000000000000000000
            });

        (uint256 amount0, uint256 amount1) = positionManager.decreaseLiquidity(params);

        INonfungiblePositionManager.CollectParams memory collectParams =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (uint256 remAmount0, uint256 remAmount1) = positionManager.collect(collectParams);

        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));
        
        if (token0 != destinationToken) {
            (uint amountsOut0) = quoter.quoteExactInputSingle(
                token0,
                destinationToken,
                3000,
                pTokenBalance,
                0
                );
            conductUniswap(
                token0,
                destinationToken,
                paths[0],
                pTokenBalance,
                amountsOut0,
                userSlippageTolerance,
                deadline
            );
        }

        if (token1 != destinationToken) {

            (uint amountsOut1) = quoter.quoteExactInputSingle(
                token1,
                destinationToken,
                3000,
                pTokenBalance2,
                0
                );
            conductUniswap(
                token1,
                destinationToken,
                paths[1],
                pTokenBalance2,
                amountsOut1,
                userSlippageTolerance,
                deadline
            );
        }

        IERC20 dToken = IERC20(destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

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
        return destinationTokenBalance;
    }

    /**
     * @notice Unwrap a source token based to the specified destination token
     * @param sourceToken Address to the source token contract
     * @param destinationToken Address to the destination token contract
     * @param paths Paths for uniswap
     * @param tokenId Id of the position for Uniswap V3
     * @param amount Amount of source token to be unwrapped
     * @param minAmountOut Amount of destination token minimum expected
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 tokenId,
        bytes [] memory paths,
        uint256 amount,
        uint256 minAmountOut,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {

        if (tokenId == 0) {
            return swap(sourceToken, destinationToken, paths[0], amount, minAmountOut, userSlippageTolerance, deadline);
        } else {
            uint256 destAmount = removeWrap(tokenId, destinationToken, paths, amount, userSlippageTolerance, deadline);
            emit UnWrapV2(destAmount);
            return destAmount;
        }
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
     * @param theAddresses Array list describing the Uniswap router swap path
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Minimum amount of output tokens the input token can be swapped
     * for, based on the Uniswap prices and Slippage tolerance thresholds
     */
    function getAmountOutMin(
        bytes memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    )
        public
        returns (uint256)
    {
        (uint minAmountsOut) = quoter.quoteExactInput(
                theAddresses,
                amount
                );
        require(userSlippageTolerance <= 100, "userSlippageTolerance can not be larger than 100");
        return SafeMath.div(SafeMath.mul(minAmountsOut, (100 - userSlippageTolerance)), 100);
    }

    /**
     * @notice Perform a Uniswap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param path Path for uniswap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param minAmount Amount of destination token minimum expected
     * @param userSlippageTolerance Maximum permissible slippage limit
     * @return amountRecieved Tokens received once the swap is completed
     */
    function conductUniswap(
        address sellToken,
        address buyToken,
        bytes memory path,
        uint256 amount,
        uint256 minAmount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256 amountRecieved)
    {
        if (sellToken == address(0x0) && buyToken == WETH_TOKEN_ADDRESS) {
            IWETH(buyToken).deposit{value: msg.value}();
            return amount;
        }

        if (sellToken == address(0x0)) {
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
        uint24 poolFee = 3000;
        uint160 sqrtPriceLimitX96 = 0;
        
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
                sellToken,
                buyToken,
                poolFee,
                msg.sender,
                deadline,
                amount,
                minAmount,
                sqrtPriceLimitX96
            ) ;
            router.exactInputSingle{ value: msg.value }(params);
            //router.refundETH();
            
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
            }
            (uint minAmountsOut) = getAmountOutMin(path,amount,userSlippageTolerance);
            uint256 amountOut = conductUniswapT4T(
                path,
                amount,
                minAmountsOut,
                deadline
            );
            return amountOut;
        }
    }

    /**
     * @notice Using Uniswap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param path  representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param minAmount Amount of destination token minimum expected
     * @return amountOut The input token amount and all subsequent output token
     * amounts
     */
    function conductUniswapT4T(
        bytes memory path,
        uint256 amount,
        uint256 minAmount,
        uint256 deadline
    )
        internal
        returns (uint256 amountOut)
    {
        
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
                path,
                address(this),
                deadline,
                amount,
                minAmount
            );
           uint256 amountRecieved =  router.exactInput(params);
        return amountRecieved;
    }
}