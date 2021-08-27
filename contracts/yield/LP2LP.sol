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
import "../proxyLib/OwnableUpgradeable.sol";
import "../interfaces/IWrapper.sol";

contract LP2LP is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // placehodler token address for specifying eth tokens
    address public ETH_TOKEN_ADDRESS;
    address private bancorLPTokenAddress;
    mapping(uint256 => address) public platforms;

    constructor() {
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    function initialize(address _bancorLPToken) external initializeOnceOnly {
        ETH_TOKEN_ADDRESS = address(0x0);
        bancorLPTokenAddress = _bancorLPToken;
    }

    function lpTolp(
        uint256 platformFrom,
        uint256 platformTo,
        address fromLPByAddress,
        address[] memory toLPTokensByTokens,
        uint256 amountFrom
    ) external nonZeroAmount(amountFrom) returns (uint256) {
        IERC20 tokenFrom = IERC20(fromLPByAddress);
        tokenFrom.safeTransferFrom(msg.sender, address(this), amountFrom);

        require(platforms[platformFrom] != address(0x0), "The platform does not exist.");

        IWrapper fromWrapper = IWrapper(platforms[platformFrom]);
        IWrapper toWrapper = IWrapper(platforms[platformTo]);
        IWrapper.UnwrapParams memory unwrapParams = IWrapper.UnwrapParams({
            lpTokenPairAddress: fromLPByAddress,
            destinationToken: ETH_TOKEN_ADDRESS,
            path1: new address[](0),            //Todo: fix to pass path for uniswap later.
            path2: new address[](0),            //Todo: fix to pass path for uniswap later.
            amount: amountFrom,
            userSlippageToleranceAmounts: new uint[](1),  //Todo: update to set real value later.
            deadline: 0                         //Todo: update to set real value later.
        });
        fromWrapper.unwrap(unwrapParams);

        uint256 thisETHBalance = address(this).balance;
        IWrapper.WrapParams memory wrapParams = IWrapper.WrapParams({
            sourceToken: ETH_TOKEN_ADDRESS,
            destinationTokens: toLPTokensByTokens,
            path1: new address[](0),            //Todo: fix to pass path for uniswap later.
            path2: new address[](0),            //Todo: fix to pass path for uniswap later.
            amount: thisETHBalance,
            userSlippageToleranceAmounts: new uint[](1),  //Todo: update to set real value later.
            deadline: 0                         //Todo: update to set real value later.
        });
        (address lpRec, uint256 recAmount) = toWrapper.wrap{
            value: thisETHBalance
        }(wrapParams);
        uint256 currentTokenBalance;
        if (platformTo != 3) {
            IERC20 tokensRecieved = IERC20(lpRec);
            currentTokenBalance = tokensRecieved.balanceOf(address(this));
            tokensRecieved.safeTransfer(msg.sender, currentTokenBalance);
        } else {
            IERC20 tokensRecieved = IERC20(bancorLPTokenAddress);
            currentTokenBalance = tokensRecieved.balanceOf(msg.sender);
        }

        return currentTokenBalance;
    }

    function updateVBNTContract(address newAddress) external onlyOwner returns (bool) {
        bancorLPTokenAddress = newAddress;
        return true;
    }

    function updatePlatform(
        uint256 platformId,
        address wrapperAddress
    )
        external
        onlyOwner
        returns (bool)
    {
        platforms[platformId] = wrapperAddress;
        return true;
    }
}
