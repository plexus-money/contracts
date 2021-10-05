// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/IWrapper.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IFactory.sol";

/// @title Plexus LP Wrapper Contract - SushiSwap
/// @author Team Plexus
contract WrapAndUnWrapSushi is IWrapper{
    using SafeERC20 for IERC20;

    // Contract state variables
    bool public changeRecipientIsOwner;
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokenss
    address public uniAddress;
    address public sushiAddress;
    address public uniFactoryAddress;
    address public sushiFactoryAddress;
    uint256 public fee;
    uint256 public maxfee;
    address public owner;
    IRouter public sushiExchange;
    IFactory public factory;

    // events
    event WrapSushi(address lpTokenPairAddress, uint256 amount);
    event UnWrapSushi(uint256 amount);
    event LpTokenRemixWrap(address lpTokenPairAddress, uint256 amount);

    constructor(
        address _weth,
        address _uniAddress,
        address _sushiAddress,
        address _uniFactoryAddress,
        address _sushiFactoryAddress
    )
        payable
    {
        // init the addresses
        WETH_TOKEN_ADDRESS = _weth;
        uniAddress = _uniAddress;
        sushiAddress = _sushiAddress;
        uniFactoryAddress = _uniFactoryAddress;
        sushiFactoryAddress = _sushiFactoryAddress;
        
        // init the router and factories
        sushiExchange = IRouter(sushiAddress);
        factory = IFactory(sushiFactoryAddress);

        // init the fees params
        fee = 0;
        maxfee = 0;
        changeRecipientIsOwner = false;
        owner = msg.sender;
    }


    modifier onlyOwner {
      require(msg.sender == owner, "Not contract owner!");
      _;
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
     * @param changeRecipientIsOwnerBool If set to true, allows owner to collect
     * fees from pair imbalances
     */
    function updateChangeRecipientBool(bool changeRecipientIsOwnerBool)
        external
        onlyOwner
        returns (bool)
    {
        changeRecipientIsOwner = changeRecipientIsOwnerBool;
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
        sushiExchange = IRouter(newAddress);
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
        factory = IFactory(newAddress);
        sushiFactoryAddress = newAddress;
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
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    ) private returns (uint256) {
        if (sourceToken != address(0x0)) {
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }
        conductSushiSwap(sourceToken, destinationToken, path, amount, userSlippageToleranceAmount, deadline);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function chargeFees(address token1, address token2) private {

        address thisPairAddress = factory.getPair(token1, token2);

        // if we get a zero address for the pair address, then we we assume,
        // we're using the wrong factory and so we switch to the sushi one
        if (thisPairAddress == address(0)) {
            IFactory fct = IFactory(uniFactoryAddress);
            thisPairAddress = fct.getPair(token1, token2);
        }
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        IERC20 dToken1 = IERC20(token1);
        IERC20 dToken2 = IERC20(token2);

        if (fee > 0) {
            uint256 totalFee = (thisBalance * fee) / 10000;
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
        if (changeRecipientIsOwner == true) {
            changeRecipient = owner;
        }
        if (dToken1.balanceOf(address(this)) > 0) {
            dToken1.safeTransfer(changeRecipient, dToken1.balanceOf(address(this)));
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(changeRecipient, dToken2.balanceOf(address(this)));
        }

    }

    function createRemixWrap(RemixWrapParams memory params, bool crossDexRemix) private returns (address, uint256) {

        IRouter router = sushiExchange;
        IFactory fct = factory;
 
        // for a cross-dex remix we init both the router and the factory to the sushi router and factory addresses respectively
        if(crossDexRemix) {
            router = IRouter(uniAddress);
            fct = IFactory(uniFactoryAddress);
        }

        if (params.sourceTokens[0] != params.destinationTokens[0]) {
            conductSwapT4TRemix(
                router,
                params.path1,
                params.amount1,
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }
        if (params.sourceTokens[1] != params.destinationTokens[1]) {
            conductSwapT4TRemix(
                router,
                params.path2,
                params.amount2,
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        // then finally add liquidity to that pool in the respective dex
        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (crossDexRemix) {

            if (dToken1.allowance(address(this), uniAddress) < dTokenBalance1 * 2) {
                dToken1.safeIncreaseAllowance(uniAddress, dTokenBalance1 * 3);
            }

            if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2 * 2) {
                dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2 * 3);
            }

        } else {
            if (dToken1.allowance(address(this), sushiAddress) < dTokenBalance1 * 2) {
                dToken1.safeIncreaseAllowance(sushiAddress, dTokenBalance1 * 3);
            }

            if (dToken2.allowance(address(this), sushiAddress) < dTokenBalance2 * 2) {
                dToken2.safeIncreaseAllowance(sushiAddress, dTokenBalance2 * 3);
            }

        }

        // we add the remixed liquidity here
        router.addLiquidity(
            params.destinationTokens[0],
            params.destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress = fct.getPair(params.destinationTokens[0], params.destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        // charge the necesssary fees if available and also transfer change 
        chargeFees(params.destinationTokens[0], params.destinationTokens[1]);

        return (thisPairAddress, thisBalance);
    }


    function createWrap(WrapParams memory params) private returns (address, uint256) {
        uint256 amount = params.amount;
        if (params.sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            amount = msg.value;
        } else {
            IERC20(params.sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        if (params.destinationTokens[0] == address(0x0)) {
            params.destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (params.destinationTokens[1] == address(0x0)) {
            params.destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (params.sourceToken != params.destinationTokens[0]) {
            conductSushiSwap(
                params.sourceToken,
                params.destinationTokens[0],
                params.path1,
                (amount / 2),
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }
        if (params.sourceToken != params.destinationTokens[1]) {
             conductSushiSwap(
                params.sourceToken,
                params.destinationTokens[1],
                params.path2,
                (amount / 2),
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        IERC20 dToken1 = IERC20(params.destinationTokens[0]);
        IERC20 dToken2 = IERC20(params.destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken1.allowance(address(this), sushiAddress) < (dTokenBalance1 * 2) ) {
            dToken1.safeIncreaseAllowance(sushiAddress, (dTokenBalance1 * 3) );
        }

        if (dToken2.allowance(address(this), sushiAddress) < (dTokenBalance2 * 2) ) {
            dToken2.safeIncreaseAllowance(sushiAddress, (dTokenBalance2 * 3) );
        }

        sushiExchange.addLiquidity(
            params.destinationTokens[0],
            params.destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress = factory.getPair(params.destinationTokens[0], params.destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        // charge the necesssary fees if available and also transfer change 
        chargeFees(params.destinationTokens[0], params.destinationTokens[1]);

        return (thisPairAddress, thisBalance);
    }

     /**
     * @notice Wrap a source token based on the specified
     * @param params params of struct WrapParams
     * // contains following properties
       // sourceToken Address to the source token contract
       // destinationTokens Array describing the token(s) which the source
       // paths Paths for sushi
       // amount Amount of source token to be wrapped
       // userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(
        WrapParams memory params
    )
        override
        external
        payable
        returns (address, uint256)
    {
        //address[][] memory _paths = splitPath(params.paths, params.destinationTokens[0]);
        if (params.destinationTokens.length == 1) {
            uint256 swapAmount = swap(params.sourceToken, params.destinationTokens[0], params.path1, params.amount, params.userSlippageToleranceAmounts[0], params.deadline);
            return (params.destinationTokens[0], swapAmount);
        } else {
            (address lpTokenPairAddress, uint256 lpTokenAmount) = createWrap(params);
            emit WrapSushi(lpTokenPairAddress, lpTokenAmount);
            return (lpTokenPairAddress, lpTokenAmount);
        }
    }

      // the function that does the actual liquidity removal
    function removePoolLiquidity(
        address lpTokenAddress,
        uint256 amount,
        uint256 minUnwrapAmount1,
        uint256 minUnwrapAmount2,
        uint256 deadline
    )
    private returns (uint256, uint256){

        ILPERC20 lpTokenInfo = ILPERC20(lpTokenAddress);
        address token0 = lpTokenInfo.token0();
        address token1 = lpTokenInfo.token1();

        sushiExchange.removeLiquidity(
            token0,
            token1,
            amount,
            minUnwrapAmount1,
            minUnwrapAmount2,
            address(this),
            deadline
        );

        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));

        return (pTokenBalance, pTokenBalance2);
    }

   // Function that does the actual unwrapping and converts the 2 pool tokens to the output token
    function removeWrap(UnwrapParams memory params) private returns (uint256){
        address originalDestinationToken = params.destinationToken;

        IERC20 sToken = IERC20(params.lpTokenPairAddress);
        if (params.destinationToken == address(0x0)) {
            params.destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (params.lpTokenPairAddress != address(0x0)) {
            sToken.safeTransferFrom(msg.sender, address(this), params.amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(params.lpTokenPairAddress);
        address token0 = thisLpInfo.token0();
        address token1 = thisLpInfo.token1();

        if (sToken.allowance(address(this), sushiAddress) < (params.amount * 2)) {
            sToken.safeIncreaseAllowance(sushiAddress, (params.amount *3));
        }

      
        // unwrap the LP token to get the constituent tokens
        ( uint256  pTokenBalance,  uint256 pTokenBalance2 )= removePoolLiquidity(
            params.lpTokenPairAddress,
            params.amount,
            params.minUnwrapAmounts[0],
            params.minUnwrapAmounts[1],
            params.deadline
        );

        if (token0 != params.destinationToken) {
            conductSushiSwap(
                token0,
                params.destinationToken,
                params.path1,
                pTokenBalance,
                params.userSlippageToleranceAmounts[0],
                params.deadline
            );
        }

        if (token1 != params.destinationToken) {
            conductSushiSwap(
                token1,
                params.destinationToken,
                params.path2,
                pTokenBalance2,
                params.userSlippageToleranceAmounts[1],
                params.deadline
            );
        }

        IERC20 dToken = IERC20(params.destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

        if (originalDestinationToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).withdraw(destinationTokenBalance);
            if (fee > 0) {
                uint256 totalFee = (address(this).balance * fee) / 10000;
                if (totalFee > 0) {
                    payable(owner).transfer(totalFee);
                }
                    payable(msg.sender).transfer(address(this).balance);
            } else {
                payable(msg.sender).transfer(address(this).balance);
            }
        } else {
            if (fee > 0) {
                uint256 totalFee = (destinationTokenBalance * fee) / 10000;
                if (totalFee > 0) {
                    dToken.safeTransfer(owner, totalFee);
                }
                destinationTokenBalance = dToken.balanceOf(address(this));
                dToken.safeTransfer(msg.sender, destinationTokenBalance);
            } else {
                dToken.safeTransfer(msg.sender, destinationTokenBalance);
            }
        }

        emit UnWrapSushi(destinationTokenBalance);

        return destinationTokenBalance;
    }

     /**
     * @notice Unwrap a source token based to the specified destination token
     * @param params params of struct UnwrapParams
        it contains following properties
        // param lpTokenPairAddress address for lp token
        // destinationToken Address of the destination token contract
        // paths Paths for sushi
        // amount Amount of source token to be unwrapped
        // userSlippageToleranceAmounts Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        UnwrapParams memory params
    )
        override
        public
        payable
        returns (uint256)
    {
        uint256 destAmount = removeWrap(params);
        return destAmount;
    }

   /**
     * @notice Unwrap a source token and wrap it into a different destination token
     * @param params Remix params having following properties
        // lpTokenPairAddress Address for the LP pair to remix
        // unwrapOutputToken Address for the initial output token of remix
        // destinationTokens Address to the destination tokens to be remixed to
        // unwrapPaths Paths best uniswap trade paths for doing the unwrapping
        // wrapPaths Paths best uniswap trade paths for doing the wrapping to the new LP token
        // amount Amount of LP Token to be remixed
        // userSlippageToleranceAmounts Maximum permissible user slippage tolerance
        // deadline Timeout after which the txn should revert
        // crossDexRemix Indicates whether this is a cross-dex remix or not
     * @return Address of the LP token returned from unwrapping the source LP token
     * @return Amount of the LP token returned from unwrapping the source LP token
    */
    function remix(RemixParams memory params)
        override
        public
        payable
        returns (address, uint256)
    {
        uint lpTokenAmount = 0;
        address lpTokenAddress = address(0);

        // first of all we remove liquidity from the pool
        IERC20 lpToken = IERC20(params.lpTokenPairAddress);
       
        if (params.lpTokenPairAddress != address(0x0)) {
            lpToken.safeTransferFrom(msg.sender, address(this), params.amount);
        }

        if (lpToken.allowance(address(this), sushiAddress) < params.amount * 2) {
            lpToken.safeIncreaseAllowance(sushiAddress, params.amount * 3);
        }

        if (lpToken.allowance(address(this), uniAddress) < params.amount * 2) {
            lpToken.safeIncreaseAllowance(uniAddress, params.amount * 3);
        }

        ILPERC20 lpTokenInfo = ILPERC20(params.lpTokenPairAddress);
        address token0 = lpTokenInfo.token0();
        address token1 = lpTokenInfo.token1();

        // the actual liquidity removal from the pool
        (uint256  pTokenBalance1, uint256 pTokenBalance2) = removePoolLiquidity(
            params.lpTokenPairAddress,
            params.amount,
            params.minUnwrapAmounts[0],
            params.minUnwrapAmounts[1],
            params.deadline
        );

        // if pool liquidity removal is successful, then proceed with the remix wrap
        if (pTokenBalance1 > 0 && pTokenBalance2 > 0) {

            address[] memory sTokens = new address[](2);
            sTokens[0] = token0;
            sTokens[1] = token1;

            if (params.crossDexRemix) {

                IERC20 sToken0 = IERC20(sTokens[0]);
                if (sToken0.allowance(address(this), uniAddress) < pTokenBalance1 * 2) {
                    sToken0.safeIncreaseAllowance(uniAddress, pTokenBalance1 * 3);
                }

                IERC20 sToken1 = IERC20(sTokens[1]);
                if (sToken1.allowance(address(this), uniAddress) < pTokenBalance2 * 2) {
                    sToken1.safeIncreaseAllowance(uniAddress, pTokenBalance2 * 3);
                }

            } else {
                IERC20 sToken0 = IERC20(sTokens[0]);
                if (sToken0.allowance(address(this), sushiAddress) < pTokenBalance1 * 2) {
                    sToken0.safeIncreaseAllowance(sushiAddress, pTokenBalance1 * 3);
                }

                IERC20 sToken1 = IERC20(sTokens[1]);
                if (sToken1.allowance(address(this), sushiAddress) < pTokenBalance2 * 2) {
                    sToken1.safeIncreaseAllowance(sushiAddress, pTokenBalance2 * 3);
                }
            }

            // then now we create the new LP token
            RemixWrapParams memory remixParams = RemixWrapParams({
                sourceTokens: sTokens,
                destinationTokens: params.destinationTokens,
                path1: params.wrapPath1,
                path2: params.wrapPath2,
                amount1: pTokenBalance1,
                amount2: pTokenBalance2,
                userSlippageToleranceAmounts: params.remixWrapSlippageToleranceAmounts,
                deadline:  params.deadline
            });

            // do the actual remix
            (lpTokenAddress, lpTokenAmount) = createRemixWrap(remixParams, params.crossDexRemix);

            emit LpTokenRemixWrap(lpTokenAddress, lpTokenAmount);
        }

        return (lpTokenAddress, lpTokenAmount);
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
    function getAmountsOut(address[] memory theAddresses, uint256 amount)
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
     * @notice Retrieve the details of the constituent tokens in an LP Token/Pair
     * @param lpTokenAddress Address to the LP token
     * @return token0Name Name of token 0
     * @return token0Symbol Symbol of token 0
     * @return token0Decimals Decimal of token 0
     * @return token1Name Namme of token 1
     * @return token1Symbol Symbol of token 1
     * @return token1Decimals Symbol of token 1
     */
    function getPoolTokensDetails(address lpTokenAddress)
        external
        view
        returns (string memory token0Name, string memory token0Symbol, uint256 token0Decimals, 
            string memory token1Name, string memory token1Symbol, uint256 token1Decimals)
    {
        // get the pool token addresses
        address token0 = ILPERC20(lpTokenAddress).token0();
        address token1 = ILPERC20(lpTokenAddress).token1();

        // Then get the pool token  details
        string memory t0Name = ERC20(token0).name();
        string memory t0Symbol = ERC20(token0).symbol();
        uint256 t0Decimals = ERC20(token0).decimals();
        string memory t1Name = ERC20(token0).name();
        string memory t1Symbol = ERC20(token1).symbol();
        uint256 t1Decimals = ERC20(token1).decimals();

        return (t0Name, t0Symbol, t0Decimals, t1Name, t1Symbol, t1Decimals);
    }


     /**
     * @notice Perform a SushiSwap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param userSlippageToleranceAmount Maximum permissible slippage limit
     * @return amounts1 Tokens received once the swap is completed
     */
    function conductSushiSwap(
        address sellToken,
        address buyToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
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
            sushiExchange.swapExactETHForTokens{value: msg.value}(
                userSlippageToleranceAmount,
                path,
                address(this),
                deadline
            );
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), sushiAddress) < (amount * 2) ) {
                sToken.safeIncreaseAllowance(sushiAddress, (amount * 3) );
            }

            uint256[] memory amounts = conductSushiSwapT4T(
                path,
                amount,
                userSlippageToleranceAmount,
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
     * @param userSlippageToleranceAmount Maximum permissible slippage tolerance
     * @return amounts1 The input token amount and all subsequent output token
     * amounts
     */
    function conductSushiSwapT4T(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts1)
    {
        uint256[] memory amounts = sushiExchange.swapExactTokensForTokens(
            amount,
            userSlippageToleranceAmount,
            theAddresses,
            address(this),
            deadline
        );
        return amounts;
    }

    /**
     * @notice Using either Uniswap or Sushiswap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param path Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageToleranceAmount Maximum permissible slippage tolerance
     * @return amounts_ The input token amount and all subsequent output token
     * amounts
     */
    function conductSwapT4TRemix(
        IRouter router,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageToleranceAmount,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts_)
    {
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                amount,
                userSlippageToleranceAmount,
                path,
                address(this),
                deadline
            );
        return amounts;
    }
}