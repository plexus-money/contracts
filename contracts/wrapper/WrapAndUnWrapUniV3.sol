// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../proxyLib/OwnableUpgradeable.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/uniswap/IUniswapV3Factory.sol";
import "../interfaces/uniswap/IUniswapV3Router.sol";
import "../interfaces/uniswap/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/uniswap/IERC721Receiver.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "hardhat/console.sol";

/// @title Plexus LP Wrapper Contract
/// @author Team Plexus
contract WrapAndUnWrapUniV3 is
    IERC721Receiver,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback
{
    using SafeERC20 for IERC20;
    // Contract state variables
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    bool public changeRecpientIsOwner;
    address private uniFactoryAddress;
    uint256 public fee;
    uint256 public maxfee;
    address public owner;
    IUniswapV3Factory private factory;
    ISwapRouter private router;
    address private routerAddress;
    INonfungiblePositionManager private positionManager;
    IQuoter private quoter;
    event WrapV3(uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1);
    event UnWrapV3(uint256 amount);

    constructor(
        address _weth,
        address _routerAddress,
        address _uniFactoryAddress,
        address _positionManager,
        address _quoter
    ) payable {
        WETH_TOKEN_ADDRESS = _weth;
        routerAddress = _routerAddress;
        router = ISwapRouter(routerAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapV3Factory(uniFactoryAddress);
        positionManager = INonfungiblePositionManager(_positionManager);
        quoter = IQuoter(_quoter);
        fee = 0;
        maxfee = 0;
        changeRecpientIsOwner = false;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner!");
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

    struct ReturnParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
    }

    struct WrapParams {
        address sourceToken;
        address[] destinationTokens;
        bytes[] paths;
        uint256 amount;
        uint256[] minAmounts;
        uint24 poolFee;
        int24 tickLower;
        int24 tickUpper;
        uint256 userSlippageTolerance;
        uint256 deadline;
    }

    struct removeWrapParams {
        uint256 tokenId;
        address destinationToken;
        bytes[] paths;
        uint256 amount;
        uint256 userSlippageTolerance;
        uint256 deadline;
    }

    struct conductUniswapParams {
        address sellToken;
        address buyToken;
        bytes path;
        uint256 amount;
        uint256 minAmount;
        uint256 userSlippageTolerance;
        uint256 deadline;
    }

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
     * @notice Update the Uniswap factory contract address
     * @param newAddress Uniswap factory contract address to be updated
     */
    function updateUniswapFactory(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        factory = IUniswapV3Factory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
    }

    /**
     * @notice Update the Uniswap Router contract address
     * @param newAddress Uniswap Router contract address to be updated
     */
    function updateUniswapRouter(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        router = ISwapRouter(newAddress);
        routerAddress = newAddress;
        return true;
    }

    /**
     * @notice Update the Uniswap Quoter contract address
     * @param newAddress Uniswap Quoter contract address to be updated
     */
    function updateUniswapQuoter(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        quoter = IQuoter(newAddress);
        return true;
    }

    /**
     * @notice Update the Uniswap Position Manager contract address
     * @param newAddress Uniswap Position Manager contract address to be updated
     */
    function updatePositionManager(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        positionManager = INonfungiblePositionManager(newAddress);
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
    ) public onlyOwner returns (bool) {
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
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // get position information
        return this.onERC721Received.selector;
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {}

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address sender = abi.decode(data, (address));
        if (amount0Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).transferFrom(
                sender,
                msg.sender,
                uint256(amount0Delta)
            );
        } else if (amount1Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).transferFrom(
                sender,
                msg.sender,
                uint256(amount1Delta)
            );
        }
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
            IERC20(sourceToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        conductUniswapParams memory input_params = conductUniswapParams(
            sourceToken,
            destinationToken,
            path,
            amount,
            minAmount,
            userSlippageTolerance,
            deadline
        );
        conductUniswap(input_params);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function createWrap(WrapParams memory params)
        private
        returns (
            uint256,
            uint128,
            uint256,
            uint256
        )
    {
        if (params.sourceToken == address(0x0)) {
            //IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            // params.amount = msg.value;
        } else {
            IERC20(params.sourceToken).safeTransferFrom(
                msg.sender,
                address(this),
                params.amount
            );
        }

        if (params.destinationTokens[0] == address(0x0)) {
            params.destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (params.destinationTokens[1] == address(0x0)) {
            params.destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (params.sourceToken != params.destinationTokens[0]) {
            conductUniswapParams memory swapParams0 = conductUniswapParams(
                params.sourceToken,
                params.destinationTokens[0],
                params.paths[0],
                params.amount / 2,
                params.minAmounts[0],
                params.userSlippageTolerance,
                params.deadline
            );
            conductUniswap(swapParams0);
        }
        if (params.sourceToken != params.destinationTokens[1]) {
            conductUniswapParams memory swapParams1 = conductUniswapParams(
                params.sourceToken,
                params.destinationTokens[1],
                params.paths[1],
                params.amount / 2,
                params.minAmounts[1],
                params.userSlippageTolerance,
                params.deadline
            );
            conductUniswap(swapParams1);
        }

        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));
        console.log(dTokenBalance1,dTokenBalance2);
        if (
            dToken1.allowance(address(this), address(positionManager)) <
            (dTokenBalance1 * 2 )
        ) {
            dToken1.safeIncreaseAllowance(
                address(positionManager),
                dTokenBalance1 * 3
            );
        }

        if (
            dToken2.allowance(address(this), address(positionManager)) <
            dTokenBalance2 * 2
        ) {
            dToken2.safeIncreaseAllowance(
                address(positionManager),
                dTokenBalance2 * 3
            );
        }

        // Transfer any change to changeRecipient
        // (from a pair imbalance. Should never be more than a few basis points)
        address changeRecipient = msg.sender;
        if (changeRecpientIsOwner == true) {
            changeRecipient = msg.sender;
        }
        if (fee > 0) {
            uint256 dToken1Balance = dToken1.balanceOf(address(this));
            uint256 halfOfFee1 = (dToken1Balance * fee) / (10000);
            if (halfOfFee1 > 0) {
                dToken1.safeTransfer(changeRecipient, halfOfFee1);
                dTokenBalance1 = dToken1Balance - halfOfFee1;
            }
            uint256 dToken2Balance = dToken2.balanceOf(address(this));
            uint256 halfOfFee2 = (dToken2Balance * fee) / (10000);
            if (halfOfFee2 > 0) {
                dToken2.safeTransfer(changeRecipient, halfOfFee2);
                dTokenBalance2 = dToken2Balance - halfOfFee2;
            }
        }
        if (params.sourceToken == address(0x0))
            params.sourceToken = WETH_TOKEN_ADDRESS;
        (address token0, address token1) = sortTokens(params.sourceToken, params.destinationTokens[1]); 
        INonfungiblePositionManager.MintParams
            memory mint_params = INonfungiblePositionManager.MintParams(
                token0,
                token1,
                params.poolFee,
                params.tickLower,
                params.tickUpper,
                dToken1.balanceOf(address(this)),
                dToken2.balanceOf(address(this)),
                params.minAmounts[0],
                params.minAmounts[1],
                address(this),
                params.deadline
            );
        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = positionManager.mint(mint_params);
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId);

        if (dToken1.balanceOf(address(this)) > 0) {
            dToken1.safeTransfer(
                changeRecipient,
                dToken1.balanceOf(address(this))
            );
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(
                changeRecipient,
                dToken2.balanceOf(address(this))
            );
        }
        return (tokenId, liquidity, amount0, amount1);
    }

    /**
     * @notice Wrap a source token based on the specified
     * destination token(s)
     * @param params input params of struct wrapParams
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(WrapParams memory params)
        public
        payable
        returns (
            uint256,
            uint128,
            uint256,
            uint256
        )
    {
        if (params.destinationTokens.length == 1) {
            uint256 swapAmount = swap(
                params.sourceToken,
                params.destinationTokens[0],
                params.paths[0],
                params.amount,
                params.minAmounts[0],
                params.userSlippageTolerance,
                params.deadline
            );
            return (0, 0, 0, swapAmount);
        } else {
            ReturnParams memory returnParams;
            (
                returnParams.tokenId,
                returnParams.liquidity,
                returnParams.amount0,
                returnParams.amount1
            ) = createWrap(params);
            emit WrapV3(returnParams.tokenId,
                returnParams.liquidity,
                returnParams.amount0,
                returnParams.amount1);
            return (
                returnParams.tokenId,
                returnParams.liquidity,
                returnParams.amount0,
                returnParams.amount1
            );
        }
    }

    function removeWrap(removeWrapParams memory removeWrap_params)
        private
        returns (uint256)
    {
        address originalDestinationToken = removeWrap_params.destinationToken;

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

        ) = positionManager.positions(removeWrap_params.tokenId);
        if (removeWrap_params.destinationToken == address(0x0)) {
            removeWrap_params.destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (removeWrap_params.tokenId != 0) {
            positionManager.safeTransferFrom(
                msg.sender,
                address(this),
                removeWrap_params.tokenId
            );
        }
        positionManager.approve(address(router), removeWrap_params.tokenId);

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams(
                removeWrap_params.tokenId,
                liquidity,
                0,
                0,
                removeWrap_params.deadline
            );

        positionManager.decreaseLiquidity(params);

        INonfungiblePositionManager.CollectParams
            memory collectParams = INonfungiblePositionManager.CollectParams(
                removeWrap_params.tokenId,
                address(this),
                type(uint128).max,
                type(uint128).max
            );

        positionManager.collect(collectParams);
        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));
        if (token0 != removeWrap_params.destinationToken) {
            uint256 amountsOut0 = getAmountOutMin(
                removeWrap_params.paths[0],
                pTokenBalance,
                removeWrap_params.userSlippageTolerance
            );
            conductUniswapParams memory swapParams0 = conductUniswapParams(
                token0,
                removeWrap_params.destinationToken,
                removeWrap_params.paths[0],
                pTokenBalance,
                amountsOut0,
                removeWrap_params.userSlippageTolerance,
                removeWrap_params.deadline
            );
            conductUniswap(swapParams0);
        }

        if (token1 != removeWrap_params.destinationToken) {
            uint256 amountsOut1 = getAmountOutMin(
                removeWrap_params.paths[1],
                pTokenBalance2,
                removeWrap_params.userSlippageTolerance
            );
            conductUniswapParams memory swapParams1 = conductUniswapParams(
                token1,
                removeWrap_params.destinationToken,
                removeWrap_params.paths[1],
                pTokenBalance2,
                amountsOut1,
                removeWrap_params.userSlippageTolerance,
                removeWrap_params.deadline
            );
            conductUniswap(swapParams1);
        }

        IERC20 dToken = IERC20(removeWrap_params.destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

        if (originalDestinationToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).withdraw(destinationTokenBalance);
            if (fee > 0) {
                uint256 totalFee = (address(this).balance * fee) / (10000);
                if (totalFee > 0) {
                    payable(msg.sender).transfer(totalFee);
                }
                payable(msg.sender).transfer(address(this).balance);
            } else {
                payable(msg.sender).transfer(address(this).balance);
            }
        } else {
            if (fee > 0) {
                uint256 totalFee = (destinationTokenBalance * fee) / (10000);
                if (totalFee > 0) {
                    dToken.safeTransfer(msg.sender, totalFee);
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
     * @param removeWrap_params unwrap struct params
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(removeWrapParams memory removeWrap_params)
        public
        payable
        returns (uint256)
    {
        require(removeWrap_params.tokenId != 0, "No Liquidity Token to unWrap");
        uint256 destAmount = removeWrap(removeWrap_params);
        emit UnWrapV3(destAmount);
        return destAmount;
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
    ) public returns (uint256) {
        uint256 minAmountsOut = quoter.quoteExactInput(theAddresses, amount);
        require(
            userSlippageTolerance <= 100,
            "userSlippageTolerance can not be larger than 100"
        );
        return
                (minAmountsOut * (100 - userSlippageTolerance)) /
                100;
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Perform a Uniswap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param input_params Address to the token being sold as part of the swap
     * @return amountRecieved Tokens received once the swap is completed
     */
    function conductUniswap(conductUniswapParams memory input_params)
        internal
        returns (uint256 amountRecieved)
    {
        if (
            input_params.sellToken == address(0x0) &&
            input_params.buyToken == WETH_TOKEN_ADDRESS
        ) {
            IWETH(input_params.buyToken).deposit{value: input_params.amount}();
            return input_params.amount;
        }

        if (input_params.sellToken == address(0x0)) {
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint24 poolFee = 3000;
            uint160 sqrtPriceLimitX96 = 0;
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: input_params.amount}();
            IERC20(WETH_TOKEN_ADDRESS).safeApprove(
                address(router),
                input_params.amount
            );
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams(
                    WETH_TOKEN_ADDRESS,
                    input_params.buyToken,
                    poolFee,
                    address(this),
                    input_params.deadline,
                    input_params.amount,
                    input_params.minAmount,
                    sqrtPriceLimitX96
                );
            uint256 amountOut = router.exactInputSingle(params);
            return amountOut;
            //router.refundETH();
        } else {
            IERC20 sToken = IERC20(input_params.sellToken);
            if (
                sToken.allowance(address(this), address(router)) <
                input_params.amount * 2
            ) {
                sToken.safeIncreaseAllowance(
                    address(router),
                    input_params.amount * 3
                );
            }
            uint256 amountOut = conductUniswapT4T(
                input_params.path,
                input_params.amount,
                input_params.minAmount,
                input_params.deadline
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
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams(path, address(this), deadline, amount, minAmount);
        uint256 amountRecieved = router.exactInput(params);
        return amountRecieved;
    }
}
