// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/token/IWETH.sol";
import "./interfaces/token/ILPERC20.sol";
import "./interfaces/sushiswap/ISushiV2.sol";
import "./interfaces/uniswap/IUniswapFactory.sol";

/// @title Plexus LP Wrapper Contract - SushiSwap
/// @author Team Plexus
contract WrapAndUnWrapSushi is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract state variables
    address public ETH_TOKEN_ADDRESS; // Contract address for ETH tokens
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    bool public changeRecpientIsOwner;
    address private sushiAddress;
    address private uniFactoryAddress;
    uint256 private approvalAmount;
    uint256 private longTimeFromNow;
    uint256 public fee;
    uint256 public maxfee;
    mapping(address => address[]) public lpTokenAddressToPairs;
    mapping(string => address) public stablecoins;
    mapping(address => mapping(address => address[])) public presetPaths;
    IWETH private wethToken;
    ISushiV2 private sushiExchange;
    IUniswapFactory private factory;

    constructor() payable {}

    /**
     * @notice Initialize the Sushi Wrapper contract
     * @param _weth Address to the WETH token contract
     * @param _sushiAddress Address to the SushiSwap contract
     * @param _uniFactoryAddress Address to the Uniswap factory contract
     * @param _dai Address to the DAI token contract
     * @param _usdt Address to the USDT token contract
     * @param _usdc Address to the USDC token contract
     */
    function initialize(
        address _weth,
        address _sushiAddress,
        address _uniFactoryAddress,
        address _dai,
        address _usdt,
        address _usdc
    ) 
        public 
        initializeOnceOnly 
    {
        ETH_TOKEN_ADDRESS = address(0x0);
        WETH_TOKEN_ADDRESS = _weth;
        wethToken = IWETH(WETH_TOKEN_ADDRESS);
        approvalAmount = 1000000000000000000000000000000;
        longTimeFromNow = 1000000000000000000000000000;
        sushiAddress = _sushiAddress;
        sushiExchange = ISushiV2(sushiAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapFactory(uniFactoryAddress);
        fee = 0;
        maxfee = 0;
        stablecoins["DAI"] = _dai;
        stablecoins["USDT"] = _usdt;
        stablecoins["USDC"] = _usdc;
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
     * @notice Update token contract address for a given stablecoin
     * @param coinName String identifier to the given stablecoin
     * @param newAddress Updated contract address for the stablecoin
     */
    function updateStableCoinAddress(string memory coinName, address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        stablecoins[coinName] = newAddress;
        return true;
    }

    /**
     * @notice Update the preset path to implement a swap between two tokens
     * @param sellToken Contract address for the token swap's sell token
     * @param buyToken Contract address for the token swap's buy token 
     * @param newPath Array representing the updated path between the two 
     * tokens
     */
    function updatePresetPaths(
        address sellToken,
        address buyToken,
        address[] memory newPath
    ) 
        external 
        onlyOwner 
        returns (bool) 
    {
        presetPaths[sellToken][buyToken] = newPath;
        return true;
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
    function updateUniswapFactory(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        factory = IUniswapFactory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
    }

    /**
     * @notice Register a LP token with the underlying token pair
     * @param lpAddress Address to the LP token's contract
     * @param token1 Address to the LP's first token
     * @param token2 Address to the LP's second token
     */
    function addLPPair(
        address lpAddress,
        address token1,
        address token2
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        lpTokenAddressToPairs[lpAddress] = [token1, token2];
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
        if (address(token) == ETH_TOKEN_ADDRESS) {
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

    /**
     * @notice Wrap a source token based on the specified 
     * destination token(s) 
     * @param sourceToken Address to the source token contract
     * @param destinationTokens Array describing the token(s) which the source
     * token will be wrapped into
     * @param amount Amount of source token to be wrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the 
     * amount of wrapped tokens
     */
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) 
        public 
        payable 
        returns (address, uint256) 
    {
        IERC20 sToken = IERC20(sourceToken);
        IERC20 dToken = IERC20(destinationTokens[0]);

        if (destinationTokens.length == 1) {
            if (sourceToken != ETH_TOKEN_ADDRESS) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);

                if (
                    sToken.allowance(address(this), sushiAddress) <
                    amount.mul(2)
                ) {
                    sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
                }
            }

            conductUniswap(
                sourceToken,
                destinationTokens[0],
                amount,
                userSlippageTolerance,
                deadline
            );
            uint256 thisBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, thisBalance);
            return (destinationTokens[0], thisBalance);
        } else {
            bool updatedweth = false;
            if (sourceToken == ETH_TOKEN_ADDRESS) {
                IWETH sToken1 = IWETH(WETH_TOKEN_ADDRESS);
                sToken1.deposit{value: msg.value}();
                sToken = IERC20(WETH_TOKEN_ADDRESS);
                amount = msg.value;
                sourceToken = WETH_TOKEN_ADDRESS;
                updatedweth = true;
            }

            if (sourceToken != ETH_TOKEN_ADDRESS && updatedweth == false) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);
                if (
                    sToken.allowance(address(this), sushiAddress) <
                    amount.mul(2)
                ) {
                    sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
                }
            }

            if (destinationTokens[0] == ETH_TOKEN_ADDRESS) {
                destinationTokens[0] = WETH_TOKEN_ADDRESS;
            }
            if (destinationTokens[1] == ETH_TOKEN_ADDRESS) {
                destinationTokens[1] = WETH_TOKEN_ADDRESS;
            }

            if (sourceToken != destinationTokens[0]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[0],
                    amount.div(2),
                    userSlippageTolerance,
                    deadline
                );
            }

            if (sourceToken != destinationTokens[1]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[1],
                    amount.div(2),
                    userSlippageTolerance,
                    deadline
                );
            }

            IERC20 dToken2 = IERC20(destinationTokens[1]);
            uint256 dTokenBalance = dToken.balanceOf(address(this));
            uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

            if (
                dToken.allowance(address(this), sushiAddress) <
                dTokenBalance.mul(2)
            ) {
                dToken.safeIncreaseAllowance(
                    sushiAddress,
                    dTokenBalance.mul(3)
                );
            }

            if (
                dToken2.allowance(address(this), sushiAddress) <
                dTokenBalance2.mul(2)
            ) {
                dToken2.safeIncreaseAllowance(
                    sushiAddress,
                    dTokenBalance2.mul(3)
                );
            }

            sushiExchange.addLiquidity(
                destinationTokens[0],
                destinationTokens[1],
                dTokenBalance,
                dTokenBalance2,
                1,
                1,
                address(this),
                longTimeFromNow
            );

            address thisPairAddress = factory.getPair(
                destinationTokens[0],
                destinationTokens[1]
            );
            IERC20 lpToken = IERC20(thisPairAddress);
            lpTokenAddressToPairs[thisPairAddress] = [
                destinationTokens[0],
                destinationTokens[1]
            ];
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

            // Transfer any change to changeRecipient (from a pair imbalance. 
            // Should never be more than a few basis points)
            address changeRecipient = msg.sender;
            if (changeRecpientIsOwner == true) {
                changeRecipient = owner();
            }
            if (dToken.balanceOf(address(this)) > 0) {
                dToken.safeTransfer(
                    changeRecipient,
                    dToken.balanceOf(address(this))
                );
            }
            if (dToken2.balanceOf(address(this)) > 0) {
                dToken2.safeTransfer(
                    changeRecipient,
                    dToken2.balanceOf(address(this))
                );
            }

            return (thisPairAddress, thisBalance);
        }
    }

    /**
     * @notice Unwrap a source token based to the specified destination token 
     * @param sourceToken Address to the source token contract
     * @param destinationToken Address to the destination token contract
     * @param amount Amount of source token to be unwrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) 
        public 
        payable 
        returns (uint256) 
    {
        address originalDestinationToken = destinationToken;
        IERC20 sToken = IERC20(sourceToken);
        if (destinationToken == ETH_TOKEN_ADDRESS) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }
        IERC20 dToken = IERC20(destinationToken);

        if (sourceToken != ETH_TOKEN_ADDRESS) {
            sToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(sourceToken);
        lpTokenAddressToPairs[sourceToken] = [
            thisLpInfo.token0(),
            thisLpInfo.token1()
        ];

        if (lpTokenAddressToPairs[sourceToken].length != 0) {
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }

            sushiExchange.removeLiquidity(
                lpTokenAddressToPairs[sourceToken][0],
                lpTokenAddressToPairs[sourceToken][1],
                amount,
                0,
                0,
                address(this),
                longTimeFromNow
            );

            IERC20 pToken;
            pToken = IERC20(lpTokenAddressToPairs[sourceToken][0]);
            uint256 pTokenBalance = pToken.balanceOf(address(this));

            if (pToken.allowance(address(this), sushiAddress) < pTokenBalance.mul(2)) {
                pToken.safeIncreaseAllowance(
                    sushiAddress,
                    pTokenBalance.mul(3)
                );
            }

            pToken = IERC20(lpTokenAddressToPairs[sourceToken][1]);
            uint256 pTokenBalance2 = pToken.balanceOf(address(this));

            if (pToken.allowance(address(this), sushiAddress) < pTokenBalance2.mul(2)) {
                pToken.safeIncreaseAllowance(
                    sushiAddress,
                    pTokenBalance2.mul(3)
                );
            }

            if (lpTokenAddressToPairs[sourceToken][0] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][0],
                    destinationToken,
                    pTokenBalance,
                    userSlippageTolerance,
                    deadline
                );
            }
            if (lpTokenAddressToPairs[sourceToken][1] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][1],
                    destinationToken,
                    pTokenBalance2,
                    userSlippageTolerance,
                    deadline
                );
            }

            uint256 destinationTokenBalance = dToken.balanceOf(address(this));

            if (originalDestinationToken == ETH_TOKEN_ADDRESS) {
                wethToken.withdraw(destinationTokenBalance);
                if (fee > 0) {
                    uint256 totalFee = (address(this).balance.mul(fee)).div(
                        10000
                    );
                    if (totalFee > 0) {
                        payable(owner()).transfer(totalFee);
                    }
                    payable(msg.sender).transfer(address(this).balance);
                } else {
                    payable(msg.sender).transfer(address(this).balance);
                }
            } else {
                if (fee > 0) {
                    uint256 totalFee = (destinationTokenBalance.mul(fee)).div(
                        10000
                    );
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
        } else {
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }
            if (sourceToken != destinationToken) {
                conductUniswap(
                    sourceToken,
                    destinationToken,
                    amount,
                    userSlippageTolerance,
                    deadline
                );
            }
            uint256 destinationTokenBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, destinationTokenBalance);
            return destinationTokenBalance;
        }
    }

    /**
     * @notice Get the best path to route a swap transaction between two tokens
     * on SushiSwap
     * @param sellToken Address to the sell token of the swap transaction 
     * @param buyToken Address to the buy token of the swap transaction
     * @param amount Amount of selling token which is to be swapped
     * @return Array of token addresses that represent the most optimal
     * transaction path for the swap
     */
    function getBestPath(
        address sellToken,
        address buyToken,
        uint256 amount
    ) 
        public 
        view 
        returns (address[] memory) 
    {
        address[] memory defaultPath = new address[](2);
        defaultPath[0] = sellToken;
        defaultPath[1] = buyToken;

        if (presetPaths[sellToken][buyToken].length != 0) {
            return presetPaths[sellToken][buyToken];
        }

        if (
            sellToken == stablecoins["DAI"] ||
            sellToken == stablecoins["USDC"] ||
            sellToken == stablecoins["USDT"]
        ) {
            return defaultPath;
        }
        if (
            buyToken == stablecoins["DAI"] ||
            buyToken == stablecoins["USDC"] ||
            buyToken == stablecoins["USDT"]
        ) {
            return defaultPath;
        }

        address[] memory daiPath = new address[](3);
        address[] memory usdcPath = new address[](3);
        address[] memory usdtPath = new address[](3);

        daiPath[0] = sellToken;
        daiPath[1] = stablecoins["DAI"];
        daiPath[2] = buyToken;

        usdcPath[0] = sellToken;
        usdcPath[1] = stablecoins["USDC"];
        usdcPath[2] = buyToken;

        usdtPath[0] = sellToken;
        usdtPath[1] = stablecoins["USDT"];
        usdtPath[2] = buyToken;

        uint256 directPathOutput = getPriceFromSushiswap(defaultPath, amount)[
            1
        ];

        uint256[] memory daiPathOutputRaw = getPriceFromSushiswap(
            daiPath,
            amount
        );
        uint256[] memory usdtPathOutputRaw = getPriceFromSushiswap(
            usdtPath,
            amount
        );
        uint256[] memory usdcPathOutputRaw = getPriceFromSushiswap(
            usdcPath,
            amount
        );

        // uint256 directPathOutput = directPathOutputRaw[directPathOutputRaw.length-1];
        uint256 daiPathOutput = daiPathOutputRaw[daiPathOutputRaw.length - 1];
        uint256 usdtPathOutput = usdtPathOutputRaw[
            usdtPathOutputRaw.length - 1
        ];
        uint256 usdcPathOutput = usdcPathOutputRaw[
            usdcPathOutputRaw.length - 1
        ];

        uint256 bestPathOutput = directPathOutput;
        address[] memory bestPath = new address[](2);
        address[] memory bestPath3 = new address[](3);
        // return defaultPath;
        bestPath = defaultPath;

        bool isTwoPath = true;

        if (directPathOutput < daiPathOutput) {
            isTwoPath = false;
            bestPathOutput = daiPathOutput;
            bestPath3 = daiPath;
        }
        if (bestPathOutput < usdcPathOutput) {
            isTwoPath = false;
            bestPathOutput = usdcPathOutput;
            bestPath3 = usdcPath;
        }
        if (bestPathOutput < usdtPathOutput) {
            isTwoPath = false;
            bestPathOutput = usdtPathOutput;
            bestPath3 = usdtPath;
        }

        require(
            bestPathOutput > 0,
            "This trade will result in getting zero tokens back. Reverting"
        );

        if (isTwoPath == true) {
            return bestPath;
        } else {
            return bestPath3;
        }
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
        try sushiExchange.getAmountsOut(amount, theAddresses) returns (
            uint256[] memory amounts
        ) {
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
        return
            SafeMath.div(
                SafeMath.mul(assetAmounts[1], (100 - userSlippageTolerance)),
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
    function conductUniswap(
        address sellToken,
        address buyToken,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) 
        internal 
        returns (uint256 amounts1) 
    {
        if (sellToken == ETH_TOKEN_ADDRESS && buyToken == WETH_TOKEN_ADDRESS) {
            wethToken.deposit{value: msg.value}();
        } else if (sellToken == address(0x0)) {
            // address[] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(
                WETH_TOKEN_ADDRESS,
                buyToken,
                amount
            );
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(
                addresses,
                amount,
                userSlippageTolerance
            );
            sushiExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                addresses,
                address(this),
                deadline
            );
        } else if (sellToken == WETH_TOKEN_ADDRESS) {
            wethToken.withdraw(amount);

            // address[] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(
                WETH_TOKEN_ADDRESS,
                buyToken,
                amount
            );
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(
                addresses,
                amount,
                userSlippageTolerance
            );
            sushiExchange.swapExactETHForTokens{value: amount}(
                amountOutMin,
                addresses,
                address(this),
                deadline
            );
        } else {
            address[] memory addresses = getBestPath(
                sellToken,
                buyToken,
                amount
            );
            uint256[] memory amounts = conductUniswapT4T(
                addresses,
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
    function conductUniswapT4T(
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