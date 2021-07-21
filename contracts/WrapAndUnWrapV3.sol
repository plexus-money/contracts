// SPDX-License-Identifier: MIT

/*
                                       `.-:+osyhhhhhhyso+:-.`
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                      `oNNNNNNh:                     /-/.           :hNNNNNNo`
                     `yNNNNNm+`                      mNNm-           `+mNNNNNy`
                    `hNNNNNd-                        hNNNm.            -dNNNNNh`
                    yNNNNNd.                         .ymNNh             .dNNNNNy
                   /NNNNNm.                            -mNNys+.          .mNNNNN/
                  `mNNNNN:                           `:hNNNNNNNs`         :NNNNNm`
                  /NNNNNh                          `+dNNNNNNNNNNd.         hNNNNN/
                  yNNNNN/               .:+syyhhhhhmNNNNNNNNNNNNNm`        /NNNNNy
                  dNNNNN.            `+dNNNNNNNNNNNNNNNNNNNNNNNmd+         .NNNNNd
                  mNNNNN`           -dNNNNNNNNNNNNNNNNNNNNNNm-             `NNNNNm
                  dNNNNN.          -NNNNNNNNNNNNNNNNNNNNNNNN+              .NNNNNd
                  yNNNNN/          dNNNNNNNNNNNNNNNNNNNNNNNN:              /NNNNNy
                  /NNNNNh         .NNNNNNNNNNNNNNNNNNNNNNNNd`              hNNNNN/
                  `mNNNNN:        -NNNNNNNNNNNNNNNNNNNNNNNh.              :NNNNNm`
                   /NNNNNm.       `NNNNNNNNNNNNNNNNNNNNNh:               .mNNNNN/
                    yNNNNNd.      .yNNNNNNNNNNNNNNNdmNNN/               .dNNNNNy
                    `hNNNNNd-    `dmNNNNNNNNNNNNdo-`.hNNh              -dNNNNNh`
                     `yNNNNNm+`   oNNmmNNNNNNNNNy.   `sNNdo.         `+mNNNNNy`
                      `oNNNNNNh:   ....++///+++++.     -+++.        :hNNNNNNo`
                        :dNNNNNNh/`                              `/hNNNNNNd:
                         `omNNNNNNdo-`                        `-odNNNNNNmo`
                           .odNNNNNNNdy+-.`              `.-+ydNNNNNNNdo.
                             `/hmNNNNNNNNmdys+//:::://+sydmNNNNNNNNmh/`
                                .+ymNNNNNNNNNNNNNNNNNNNNNNNNNNNNmy+.
                                   .:+ydmNNNNNNNNNNNNNNNNNNmdy+:.
                                       `.-:+yourewelcome+:-.`
 /$$$$$$$  /$$                                               /$$      /$$
| $$__  $$| $$                                              | $$$    /$$$
| $$  \ $$| $$  /$$$$$$  /$$   /$$ /$$   /$$  /$$$$$$$      | $$$$  /$$$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$
| $$$$$$$/| $$ /$$__  $$|  $$ /$$/| $$  | $$ /$$_____/      | $$ $$/$$ $$ /$$__  $$| $$__  $$ /$$__  $$| $$  | $$
| $$____/ | $$| $$$$$$$$ \  $$$$/ | $$  | $$|  $$$$$$       | $$  $$$| $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$  | $$
| $$      | $$| $$_____/  >$$  $$ | $$  | $$ \____  $$      | $$\  $ | $$| $$  | $$| $$  | $$| $$_____/| $$  | $$
| $$      | $$|  $$$$$$$ /$$/\  $$|  $$$$$$/ /$$$$$$$/      | $$ \/  | $$|  $$$$$$/| $$  | $$|  $$$$$$$|  $$$$$$$
|__/      |__/ \_______/|__/  \__/ \______/ |_______/       |__/     |__/ \______/ |__/  |__/ \_______/ \____  $$
                                                                                                        /$$  | $$
                                                                                                       |  $$$$$$/
                                                                                                       \______/

*/


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/token/IWETH.sol";
import "./interfaces/token/ILPERC20.sol";
import "./interfaces/uniswap/v3/INonfungiblePositionManager.sol";
import "./interfaces/uniswap/v3/ISwapRouter.sol";
import "./interfaces/uniswap/v3/IQuoter.sol";
import "./interfaces/uniswap/v3/IUniswapV3Factory.sol";
import "./interfaces/uniswap/v3/IUniswapV3Pool.sol";

contract WrapAndUnWrapV3 is OwnableUpgradeable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    //  address payable public owner;
    //placehodler token address for specifying eth tokens
    address public ETH_TOKEN_ADDRESS;
    address public WETH_TOKEN_ADDRESS;
    bool public changeRecpientIsOwner;
    address private nonfungiblePositionManagerAddress;
    uint256 public fee;
    uint256 public maxfee;
    uint256 private longTimeFromNow;
    IWETH private wethToken;
    INonfungiblePositionManager private nonfungiblePositionManager;
    ISwapRouter private swapRouter;
    IUniswapV3Factory private factory;
    address private quoterAddr;
    mapping (uint256 => address[]) public lpTokenAddressToPairs;
    mapping(string=>address) public stablecoins;
    mapping(address=>mapping(address=>address[])) public presetPaths;
    event WrapV3(uint256 tokenId, uint128 liquidity);
    struct PoolInfo {
        address token1;
        address token2;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }

    constructor() payable {
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function initialize(
        address _weth,
        address _nonfungiblePositionManagerAddress,
        address _swapRouterAddress,
        address _swapFactoryAddress,
        address _quoterAddress,
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
        longTimeFromNow = 1000000000000000000000000000;
        nonfungiblePositionManagerAddress = _nonfungiblePositionManagerAddress;
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManagerAddress);
        swapRouter = ISwapRouter(_swapRouterAddress);
        factory = IUniswapV3Factory(_swapFactoryAddress);
        quoterAddr = _quoterAddress;
        fee = 0;
        maxfee = 0;
        stablecoins["DAI"] = _dai;
        stablecoins["USDT"] = _usdt;
        stablecoins["USDC"] = _usdc;
        changeRecpientIsOwner = false;
    }

    function updateStableCoinAddress(
        string memory coinName,
        address newAddress
    )
        external
        onlyOwner
        returns (bool)
    {
        stablecoins[coinName] = newAddress;
        return true;
    }

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

    // Owner can turn on ability to collect a small fee from trade imbalances on LP conversions
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

    function updateUniswapRouter(address newAddress) external onlyOwner returns (bool) {
        swapRouter = ISwapRouter(newAddress);
        return true;
    }

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
            IERC20(token).safeTransfer(destination, amount);
        }
        return true;
    }

    function setFee(uint256 newFee) public onlyOwner returns (bool) {
        require(
            newFee <= maxfee,
            "Admin cannot set the fee higher than the current maxfee"
        );
        fee = newFee;
        return true;
    }

    function setMaxFee(uint256 newMax) public onlyOwner returns (bool) {
        require(maxfee == 0, "Admin can only set max fee once and it is perm");
        maxfee = newMax;
        return true;
    }

    function addLPPair(
        uint256 tokenId,
        address token1,
        address token2
    )
        public
        onlyOwner
        returns (bool)
    {
        lpTokenAddressToPairs[tokenId] = [token1, token2];
        return true;
    }

    function getPriceFromUniswap(address[] memory theAddresses, uint256 amount)
        public
        returns (uint256, bytes memory) {
            IUniswapV3Pool[][] memory poolPaths = _getValidPoolPaths(theAddresses, 0);
            bytes memory topUniswapPath;
            uint256 topBuyAmount = 0;
            for (uint256 j = 0; j < poolPaths.length; ++j) {
                bytes memory uniswapPath = _toUniswapPath(theAddresses, poolPaths[j]);
                try
                    IQuoter(quoterAddr).quoteExactInput
                        (uniswapPath, amount)
                        returns (uint256 buyAmount)
                {
                    if (topBuyAmount <= buyAmount) {
                        topBuyAmount = buyAmount;
                        topUniswapPath = uniswapPath;
                    }
                } catch { }
            }
            return (topBuyAmount, topUniswapPath);
    }

    function _getValidPoolPaths(
        address[] memory tokenPath,
        uint256 startIndex
    )
        private
        view
        returns (IUniswapV3Pool[][] memory poolPaths)
    {
        require(
            tokenPath.length - startIndex >= 2,
            "tokenPath too short"
        );
        uint24[3] memory validPoolFees = [
            // The launch pool fees. Could get hairier if they add more.
            uint24(0.0005e6),
            uint24(0.003e6),
            uint24(0.01e6)
        ];
        IUniswapV3Pool[] memory validPools = new IUniswapV3Pool[](validPoolFees.length);
        uint256 numValidPools = 0;
        {
            //address inputToken = tokenPath[startIndex];
            //address outputToken = tokenPath[startIndex + 1];
            for (uint256 i = 0; i < validPoolFees.length; ++i) {
                address poolAddr = factory.getPool(tokenPath[startIndex], tokenPath[startIndex + 1], validPoolFees[i]);
                IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
                if (_isValidPool(pool)) {
                    validPools[numValidPools++] = pool;
                }
            }
        }
        if (numValidPools == 0) {
            // No valid pools for this hop.
            return poolPaths;
        }
        if (startIndex + 2 == tokenPath.length) {
            // End of path.
            poolPaths = new IUniswapV3Pool[][](numValidPools);
            for (uint256 i = 0; i < numValidPools; ++i) {
                poolPaths[i] = new IUniswapV3Pool[](1);
                poolPaths[i][0] = validPools[i];
            }
            return poolPaths;
        }
        // Get paths for subsequent hops.
        IUniswapV3Pool[][] memory subsequentPoolPaths =
            _getValidPoolPaths(tokenPath, startIndex + 1);
        if (subsequentPoolPaths.length == 0) {
            // Could not complete the path.
            return poolPaths;
        }
        // Combine our pools with the next hop paths.
        poolPaths = new IUniswapV3Pool[][](
            numValidPools * subsequentPoolPaths.length
        );
        for (uint256 i = 0; i < numValidPools; ++i) {
            for (uint256 j = 0; j < subsequentPoolPaths.length; ++j) {
                uint256 o = i * subsequentPoolPaths.length + j;
                // Prepend pool to the subsequent path.
                poolPaths[o] =
                    new IUniswapV3Pool[](1 + subsequentPoolPaths[j].length);
                poolPaths[o][0] = validPools[i];
                for (uint256 k = 0; k < subsequentPoolPaths[j].length; ++k) {
                    poolPaths[o][1 + k] = subsequentPoolPaths[j][k];
                }
            }
        }
        return poolPaths;
    }

    function _toUniswapPath(
        address[] memory tokenPath,
        IUniswapV3Pool[] memory poolPath
    )
        private
        view
        returns (bytes memory uniswapPath)
    {
        require(
            tokenPath.length >= 2 && tokenPath.length == poolPath.length + 1,
            "invalid path lengths"
        );
        // Uniswap paths are tightly packed as:
        // [token0, token0token1PairFee, token1, token1Token2PairFee, token2, ...]
        uniswapPath = new bytes(tokenPath.length * 20 + poolPath.length * 3);
        uint256 o;
        assembly { o := add(uniswapPath, 32) }
        for (uint256 i = 0; i < tokenPath.length; ++i) {
            if (i > 0) {
                uint24 poolFee = poolPath[i - 1].fee();
                assembly {
                    mstore(o, shl(232, poolFee))
                    o := add(o, 3)
                }
            }
            IERC20 token = IERC20(tokenPath[i]);
            assembly {
                mstore(o, shl(96, token))
                o := add(o, 20)
            }
        }
    }

    function _isValidPool(IUniswapV3Pool pool)
        private
        view
        returns (bool isValid)
    {
        // Check if it has been deployed.
        {
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(pool)
            }
            if (codeSize == 0) {
                return false;
            }
        }
        address token0 = IUniswapV3PoolImmutables(address(pool)).token0();
        address token1 = IUniswapV3PoolImmutables(address(pool)).token1();
        // Must have a balance of both tokens.
        if (IERC20(token0).balanceOf(address(pool)) == 0) {
            return false;
        }
        if (IERC20(token1).balanceOf(address(pool)) == 0) {
            return false;
        }
        return true;
    }

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

    // Gets the best path to route the transaction on Uniswap
    function getBestPath(
        address sellToken,
        address buyToken,
        uint256 amount
    )
        public
        returns (bytes memory, uint256)
    {
        uint256 amountOutput;
        bytes memory uniPath;
        if (presetPaths[sellToken][buyToken].length != 0) {
            (amountOutput, uniPath) = getPriceFromUniswap(presetPaths[sellToken][buyToken], amount);
            return (uniPath, amountOutput);
        }

        address[] memory defaultPath = new address[](2);
        defaultPath[0] = sellToken;
        defaultPath[1] = buyToken;
        (uint256 directPathOutput, bytes memory directUniPath) = getPriceFromUniswap(defaultPath, amount);
        if (
            sellToken == stablecoins["DAI"] ||
            sellToken == stablecoins["USDC"] ||
            sellToken == stablecoins["USDT"]
        ) {
            return (directUniPath, directPathOutput);
        }
        if (
            buyToken == stablecoins["DAI"] ||
            buyToken == stablecoins["USDC"] ||
            buyToken == stablecoins["USDT"]
        ) {
            return (directUniPath, directPathOutput);
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

        (amountOutput, uniPath) = getPriceFromUniswap(daiPath, amount);
        uint256 bestPathOutput = directPathOutput;
        bytes memory bestUniPath;
        // return defaultPath;
        bestUniPath = directUniPath;
        if (directPathOutput < amountOutput) {
            bestPathOutput = amountOutput;
            bestUniPath = uniPath;
        }
        (amountOutput, uniPath) = getPriceFromUniswap(usdcPath, amount);
        if (bestPathOutput < amountOutput) {
            bestPathOutput = amountOutput;
            bestUniPath = uniPath;
        }
        (amountOutput, uniPath) = getPriceFromUniswap(usdtPath, amount);
        if (bestPathOutput < amountOutput) {
            bestPathOutput = amountOutput;
            bestUniPath = uniPath;
        }

        require(
            bestPathOutput > 0,
            "This trade will result in getting zero tokens back. Reverting"
        );

        return (bestUniPath, bestPathOutput);
    }

    function conductUniswapT4T(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    )
        internal
        returns (uint256[] memory amounts_)
    {
        uint256 deadline = 1000000000000000;

        (uint256 assetAmount, bytes memory uniPath) = getPriceFromUniswap(theAddresses, amount);
        require(userSlippageTolerance <= 100, "userSlippageTolerance can not be larger than 100");
        uint256 amountOutMin = SafeMath.div(SafeMath.mul(assetAmount, (100 - userSlippageTolerance)), 100);
        uint256 amountOut = _swap(
                uniPath,
                amount,
                amountOutMin,
                deadline
            );

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amountOut;
        return amounts;
    }

    function wrapV3(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance,
        int24 tickLower,
        int24 tickUpper,
        uint24 _fee,
        uint256 deadline
    )
    public
    payable
    returns (uint256, uint128, address)
    {
        IERC20 sToken = IERC20(sourceToken);
        if (destinationTokens.length == 1) {
            IERC20 dToken = IERC20(destinationTokens[0]);
            if (sourceToken != ETH_TOKEN_ADDRESS) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);
            }
            conductUniswap(sourceToken, destinationTokens[0], amount, userSlippageTolerance, deadline);
            uint256 thisBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, thisBalance);
            return (thisBalance, 0, destinationTokens[0]);
        } else {
            address updatedSourceToken = sourceToken;
            if (sourceToken == ETH_TOKEN_ADDRESS) {
                updatedSourceToken = WETH_TOKEN_ADDRESS;
            } else {
                sToken.safeTransferFrom(msg.sender, address(this), amount);
            }

            if(destinationTokens[1] < destinationTokens[0]) {
                address temp = destinationTokens[0];
                destinationTokens[0] = destinationTokens[1];
                destinationTokens[1] = temp;
            }

            if (destinationTokens[0] == ETH_TOKEN_ADDRESS) {
                destinationTokens[0] = WETH_TOKEN_ADDRESS;
            }
            if (destinationTokens[1] == ETH_TOKEN_ADDRESS) {
                destinationTokens[1] = WETH_TOKEN_ADDRESS;
            }
            if (updatedSourceToken != destinationTokens[0]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[0],
                    amount.div(2),
                    userSlippageTolerance,
                    deadline
                );
            }
            if (updatedSourceToken != destinationTokens[1]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[1],
                    amount.div(2),
                    userSlippageTolerance,
                    deadline
                );
            }

            PoolInfo memory poolInfo = PoolInfo(destinationTokens[0], destinationTokens[1], tickLower, tickUpper, _fee);
            (uint256 tokenId, uint128 liquidity) = _addLiquidity(poolInfo, deadline);

            IERC721 recipient = IERC721(nonfungiblePositionManagerAddress);
            recipient.safeTransferFrom(address(this), msg.sender, tokenId);
            emit WrapV3(tokenId, liquidity);
            return (tokenId, liquidity, address(0));
        }
    }

    function sqrt(uint160 x) internal pure returns (uint160 y) {
        uint160 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function calcSqrtPriceX96(uint160 amount1, uint160 amount2) internal pure returns(uint160) {
        return (sqrt(amount2) << 96) / sqrt(amount1);
    }

    function _addLiquidity(PoolInfo memory poolInfo, uint256 deadline) private returns(uint256, uint128){
        IERC20 dToken = IERC20(poolInfo.token1);
        IERC20 dToken2 = IERC20(poolInfo.token2);
        uint256 dTokenBalance = dToken.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken.allowance(address(this), address(nonfungiblePositionManager)) < dTokenBalance.mul(2)) {
            dToken.safeIncreaseAllowance(address(nonfungiblePositionManager), dTokenBalance.mul(3));
        }

        if (dToken2.allowance(address(this), address(nonfungiblePositionManager)) < dTokenBalance2.mul(2)) {
            dToken2.safeIncreaseAllowance(address(nonfungiblePositionManager), dTokenBalance2.mul(3));
        }

        uint160 sqrtPriceX96 = calcSqrtPriceX96(uint160(dTokenBalance), uint160(dTokenBalance2));
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(poolInfo.token1, poolInfo.token2, poolInfo.fee, sqrtPriceX96);
        
        INonfungiblePositionManager.MintParams memory data =
        INonfungiblePositionManager.MintParams(
            poolInfo.token1,
            poolInfo.token2,
            poolInfo.fee,
            poolInfo.tickLower,
            poolInfo.tickUpper,
            dTokenBalance,
            dTokenBalance2,
            0,
            0,
            address(this),
            deadline
        );

        (
        uint256 tokenId,
        uint128 liquidity,
        ,
        ) = nonfungiblePositionManager.mint(data);

        dTokenBalance = dToken.balanceOf(address(this));
        dTokenBalance2 = dToken2.balanceOf(address(this));
        lpTokenAddressToPairs[tokenId] = [poolInfo.token1, poolInfo.token2];
        
        address changeRecipient = msg.sender;
        if (changeRecpientIsOwner == true) {
            changeRecipient = owner();
        }
        if (dToken.balanceOf(address(this)) > 0) {
            dToken.safeTransfer(changeRecipient, dToken.balanceOf(address(this)));
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(changeRecipient, dToken2.balanceOf(address(this)));
        }

        return (tokenId, liquidity);
    }

    function unwrapV3(
        uint256 tokenId,
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
        if (destinationToken == ETH_TOKEN_ADDRESS) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }
        IERC20 dToken = IERC20(destinationToken);
        uint256 destinationTokenBalance;
        if (tokenId != 0) {
            require(lpTokenAddressToPairs[tokenId].length != 0, "no pool for this tokenId");
            IERC721 lpToken = IERC721(nonfungiblePositionManagerAddress);
            lpToken.safeTransferFrom(msg.sender, address(this), tokenId);
            _removeLiquidity(tokenId, amount, deadline);

            address[] memory tokenPair = lpTokenAddressToPairs[tokenId];
            IERC20 pToken1 = IERC20(tokenPair[0]);
            IERC20 pToken2 = IERC20(tokenPair[1]);

            uint256 pTokenBalance = pToken1.balanceOf(address(this));
            uint256 pTokenBalance2 = pToken2.balanceOf(address(this));
            if (tokenPair[0] != destinationToken) {
                conductUniswap(
                    tokenPair[0],
                    destinationToken,
                    pTokenBalance,
                    userSlippageTolerance,
                    deadline
                );
            }

            if (tokenPair[1] != destinationToken) {
                conductUniswap(
                    tokenPair[1],
                    destinationToken,
                    pTokenBalance2,
                    userSlippageTolerance,
                    deadline
                );
            }

            destinationTokenBalance = dToken.balanceOf(address(this));
            if (originalDestinationToken == ETH_TOKEN_ADDRESS) {
                wethToken.withdraw(destinationTokenBalance);
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
        } else {
            IERC20 sToken = IERC20(sourceToken);
            sToken.safeTransferFrom(msg.sender, address(this), amount);

            if (sourceToken != destinationToken) {
                conductUniswap(sourceToken, destinationToken, amount, userSlippageTolerance, deadline);
            }
            destinationTokenBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, destinationTokenBalance);
            return destinationTokenBalance;
        }
    }

    function _removeLiquidity(uint256 tokenId, uint256 amount, uint256 deadline) private {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params
        = INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: uint128(amount),
        amount0Min: 0,
        amount1Min: 0,
        deadline: deadline
        });
        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager
        .decreaseLiquidity(params);

        INonfungiblePositionManager.CollectParams memory cparams
        = INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: uint128(amount0),
        amount1Max: uint128(amount1)
        });

        nonfungiblePositionManager.collect(cparams);
        nonfungiblePositionManager.burn(tokenId);
    }

    function conductUniswap(
        address sellToken,
        address buyToken,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
    internal
    returns (uint256)
    {
        if (sellToken == ETH_TOKEN_ADDRESS) {
            wethToken.deposit{value: amount}();
            sellToken = WETH_TOKEN_ADDRESS;
            if (buyToken == WETH_TOKEN_ADDRESS) {
                return amount;
            }
        }

        if(sellToken == WETH_TOKEN_ADDRESS && buyToken == ETH_TOKEN_ADDRESS) {
            wethToken.withdraw(amount);
            return amount;
        }

        IERC20 sToken = IERC20(sellToken);
        if (sToken.allowance(address(this), address(swapRouter)) < amount.mul(2)) {
            sToken.safeIncreaseAllowance(address(swapRouter), amount.mul(3));
        }

        (bytes memory uniPath, uint256 amountOut) = getBestPath(sellToken, buyToken, amount);
        return _swap(
            uniPath,
            amount,
            SafeMath.div(SafeMath.mul(amountOut, (100 - userSlippageTolerance)), 100),
            deadline
        );
    }

    function _swap(bytes memory path, uint256 amountIn, uint256 amountOutMin, uint256 deadline) private returns (uint256) {
        ISwapRouter.ExactInputParams memory data =
        ISwapRouter.ExactInputParams(
            path,
            address(this),
            deadline,
            amountIn,
            amountOutMin
        );

        return swapRouter.exactInput(data);
    }
}
