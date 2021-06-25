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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxyLib/OwnableUpgradeable.sol";
import "./interfaces/token/IWETH.sol";
import "./interfaces/token/ILPERC20.sol";
import "./interfaces/uniswap/IUniswapV2.sol";
import "./interfaces/uniswap/IUniswapFactory.sol";

contract WrapAndUnWrap is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //  address payable public owner;
    //placehodler token address for specifying eth tokens
    address public ETH_TOKEN_ADDRESS;
    address public WETH_TOKEN_ADDRESS;
    IWETH private wethToken;
    uint256 approvalAmount;
    uint256 longTimeFromNow;
    address uniAddress;
    address uniFactoryAddress;
    IUniswapV2 private uniswapExchange;
    IUniswapFactory private factory;
    mapping (address => address[]) public lpTokenAddressToPairs;
    mapping(string=>address) public stablecoins;
    mapping(address=>mapping(address=>address[])) public presetPaths;
    bool public changeRecpientIsOwner;
    uint256 public fee;
    uint256 public maxfee;

    constructor() payable {
    }

    function initialize(address _weth, address _uniAddress, address _uniFactoryAddress, address _dai, address _usdt, address _usdc) initializeOnceOnly public {
        ETH_TOKEN_ADDRESS = address(0x0);
        WETH_TOKEN_ADDRESS = _weth;
        wethToken = IWETH(WETH_TOKEN_ADDRESS);
        approvalAmount = 1000000000000000000000000000000;
        longTimeFromNow = 1000000000000000000000000000;
        uniAddress = _uniAddress;
        uniswapExchange = IUniswapV2(uniAddress);
        uniFactoryAddress = _uniFactoryAddress;
        factory = IUniswapFactory(uniFactoryAddress);
        fee = 0;
        maxfee = 0;
        stablecoins["DAI"] = _dai;
        stablecoins["USDT"] = _usdt;
        stablecoins["USDC"] = _usdc;
        changeRecpientIsOwner = false;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        uint256 amount,
        uint256 userSlippageTolerance
    ) public payable returns (address, uint256) {
        IERC20 sToken = IERC20(sourceToken);
        IERC20 dToken = IERC20(destinationTokens[0]);

        if (destinationTokens.length == 1) {
            if (sourceToken != ETH_TOKEN_ADDRESS) {
                sToken.safeTransferFrom(msg.sender, address(this), amount);

                if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                    sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
                }
            }

            conductUniswap(sourceToken, destinationTokens[0], amount, userSlippageTolerance);
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

                if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                    sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
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
                    userSlippageTolerance
                );
            }
            if (sourceToken != destinationTokens[1]) {
                conductUniswap(
                    sourceToken,
                    destinationTokens[1],
                    amount.div(2),
                    userSlippageTolerance
                );
            }

            IERC20 dToken2 = IERC20(destinationTokens[1]);
            uint256 dTokenBalance = dToken.balanceOf(address(this));
            uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

            if (dToken.allowance(address(this), uniAddress) < dTokenBalance.mul(2)) {
                dToken.safeIncreaseAllowance(uniAddress, dTokenBalance.mul(3));
            }

            if (dToken2.allowance(address(this), uniAddress) < dTokenBalance2.mul(2)) {
                dToken2.safeIncreaseAllowance(uniAddress, dTokenBalance2.mul(3));
            }

            (, , uint256 liquidityCoins) =
                uniswapExchange.addLiquidity(
                    destinationTokens[0],
                    destinationTokens[1],
                    dTokenBalance,
                    dTokenBalance2,
                    1,
                    1,
                    address(this),
                    longTimeFromNow
                );

            address thisPairAddress =
                factory.getPair(destinationTokens[0], destinationTokens[1]);
            IERC20 lpToken = IERC20(thisPairAddress);
            lpTokenAddressToPairs[thisPairAddress] = [destinationTokens[0], destinationTokens[1]];

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

            // Transfer any change to changeRecipient (from a pair imbalance. Should never be more than a few basis points)
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

            return (thisPairAddress, thisBalance);
        }
    }

    function updateStableCoinAddress(string memory coinName, address newAddress) public onlyOwner returns (bool)
    {
        stablecoins[coinName] = newAddress;
        return true;
    }

    function updatePresetPaths(
        address sellToken,
        address buyToken,
        address[] memory newPath
    ) public onlyOwner returns (bool) {
        presetPaths[sellToken][buyToken] = newPath;
        return true;
    }

    // Owner can turn on ability to collect a small fee from trade imbalances on LP conversions
    function updateChangeRecipientBool(bool changeRecpientIsOwnerBool)
        public
        onlyOwner
        returns (bool)
    {
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }

    function unwrap(
        address sourceToken,
        address destinationToken,
        uint256 amount,
        uint256 userSlippageTolerance
    ) public payable returns (uint256) {
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
        lpTokenAddressToPairs[sourceToken] = [thisLpInfo.token0(), thisLpInfo.token1()];

        if (lpTokenAddressToPairs[sourceToken].length != 0) {
            if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
            }

            uniswapExchange.removeLiquidity(
                lpTokenAddressToPairs[sourceToken][0],
                lpTokenAddressToPairs[sourceToken][1],
                amount,
                0,
                0,
                address(this),
                longTimeFromNow
            );

            IERC20 pToken1 = IERC20(lpTokenAddressToPairs[sourceToken][0]);
            IERC20 pToken2 = IERC20(lpTokenAddressToPairs[sourceToken][1]);

            uint256 pTokenBalance = pToken1.balanceOf(address(this));
            uint256 pTokenBalance2 = pToken2.balanceOf(address(this));

            if (pToken1.allowance(address(this), uniAddress) < pTokenBalance.mul(2)) {
                pToken1.safeIncreaseAllowance(uniAddress, pTokenBalance.mul(3));
            }

            if (pToken2.allowance(address(this), uniAddress) < pTokenBalance2.mul(2)) {
                pToken2.safeIncreaseAllowance(uniAddress, pTokenBalance2.mul(3));
            }

            if (lpTokenAddressToPairs[sourceToken][0] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][0],
                    destinationToken,
                    pTokenBalance,
                    userSlippageTolerance
                );
            }

            if (lpTokenAddressToPairs[sourceToken][1] != destinationToken) {
                conductUniswap(
                    lpTokenAddressToPairs[sourceToken][1],
                    destinationToken,
                    pTokenBalance2,
                    userSlippageTolerance
                );
            }

            uint256 destinationTokenBalance = dToken.balanceOf(address(this));

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
            if (sToken.allowance(address(this), uniAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(uniAddress, amount.mul(3));
            }
            if (sourceToken != destinationToken) {
                conductUniswap(sourceToken, destinationToken, amount, userSlippageTolerance);
            }
            uint256 destinationTokenBalance = dToken.balanceOf(address(this));
            dToken.safeTransfer(msg.sender, destinationTokenBalance);
            return destinationTokenBalance;
        }
    }

    function updateUniswapExchange(address newAddress) public onlyOwner returns (bool) {
        uniswapExchange = IUniswapV2(newAddress);
        uniAddress = newAddress;
        return true;
    }

    function updateUniswapFactory(address newAddress) public onlyOwner returns (bool) {
        factory = IUniswapFactory(newAddress);
        uniFactoryAddress = newAddress;
        return true;
    }

    function conductUniswap(
        address sellToken,
        address buyToken,
        uint256 amount,
        uint256 userSlippageTolerance
    ) internal returns (uint256 amounts1) {
        if (sellToken == ETH_TOKEN_ADDRESS && buyToken == WETH_TOKEN_ADDRESS) {
            wethToken.deposit{value: msg.value}();
        } else if (sellToken == address(0x0)) {
            // address [] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(WETH_TOKEN_ADDRESS, buyToken, amount);
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(addresses, amount, userSlippageTolerance);
            uniswapExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                addresses,
                address(this),
                1000000000000000
            );
        } else if (sellToken == WETH_TOKEN_ADDRESS) {
            wethToken.withdraw(amount);
            // address [] memory addresses = new address[](2);
            address[] memory addresses = getBestPath(WETH_TOKEN_ADDRESS, buyToken, amount);
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(addresses, amount, userSlippageTolerance);
            uniswapExchange.swapExactETHForTokens{value: amount}(
                amountOutMin,
                addresses,
                address(this),
                1000000000000000
            );
        } else {
            address[] memory addresses = getBestPath(sellToken, buyToken, amount);
            uint256 [] memory amounts = conductUniswapT4T(addresses, amount, userSlippageTolerance);
            uint256 resultingTokens = amounts[amounts.length - 1];
            return resultingTokens;
        }
    }

    // Gets the best path to route the transaction on Uniswap
    function getBestPath(
        address sellToken,
        address buyToken,
        uint256 amount
    ) public view returns (address[] memory) {
        address[] memory defaultPath = new address[](2);
        defaultPath[0] = sellToken;
        defaultPath[1] = buyToken;

        if (presetPaths[sellToken][buyToken].length != 0) {
            return presetPaths[sellToken][buyToken];
        }

        if (sellToken == stablecoins["DAI"] || sellToken == stablecoins["USDC"] || sellToken == stablecoins["USDT"]) {
            return defaultPath;
        }
        if (buyToken == stablecoins["DAI"] || buyToken == stablecoins["USDC"] || buyToken == stablecoins["USDT"]) {
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

        uint256 directPathOutput = getPriceFromUniswap(defaultPath, amount)[1];

        uint256[] memory daiPathOutputRaw = getPriceFromUniswap(daiPath, amount);
        uint256[] memory usdtPathOutputRaw = getPriceFromUniswap(usdtPath, amount);
        uint256[] memory usdcPathOutputRaw = getPriceFromUniswap(usdcPath, amount);

        // uint256 directPathOutput = directPathOutputRaw[directPathOutputRaw.length-1];
        uint256 daiPathOutput = daiPathOutputRaw[daiPathOutputRaw.length - 1];
        uint256 usdtPathOutput = usdtPathOutputRaw[usdtPathOutputRaw.length - 1];
        uint256 usdcPathOutput = usdcPathOutputRaw[usdcPathOutputRaw.length - 1];

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

    function getPriceFromUniswap(address[] memory theAddresses, uint256 amount)
        public
        view
        returns (uint256[] memory amounts1) {
        try uniswapExchange.getAmountsOut(amount, theAddresses) returns (uint256[] memory amounts) {
            return amounts;
        } catch {
            uint256[] memory amounts2 = new uint256[](2);
            amounts2[0] = 0;
            amounts2[1] = 0;
            return amounts2;
        }
    }

    function getAmountOutMin(address  [] memory theAddresses, uint256 amount, uint256 userSlippageTolerance) public view returns (uint256) {
        uint256 [] memory assetAmounts = getPriceFromUniswap(theAddresses, amount);
        require(userSlippageTolerance <= 100, 'userSlippageTolerance can not be larger than 100');
        return SafeMath.div(SafeMath.mul(assetAmounts[1], (100 - userSlippageTolerance)), 100);
    }

    function conductUniswapT4T(address[] memory theAddresses, uint256 amount, uint256 userSlippageTolerance) internal returns (uint256[] memory amounts1) {
        uint256 deadline = 1000000000000000;
        uint256 amountOutMin = getAmountOutMin(theAddresses, amount, userSlippageTolerance);
        uint256[] memory amounts =
            uniswapExchange.swapExactTokensForTokens(
                amount,
                amountOutMin,
                theAddresses,
                address(this),
                deadline
            );

        return amounts;
    }

    function adminEmergencyWithdrawTokens(
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
        address lpAddress,
        address token1,
        address token2
    ) public onlyOwner returns (bool) {
        lpTokenAddressToPairs[lpAddress] = [token1, token2];
        return true;
    }

    function getLPTokenByPair(address token1, address token2) public view returns (address lpAddr) {
        address thisPairAddress = factory.getPair(token1, token2);
        return thisPairAddress;
    }

    function getUserTokenBalance(address userAddress, address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }
}