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



pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface wrapper{
    function wrap(address sourceToken, address[] memory destinationTokens, uint256 amount) external payable returns(address, uint256);
    function unwrap(address sourceToken, address destinationToken, uint256 amount) external payable returns( uint256);
}

contract LP2LP{

  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  address payable public owner;
  //placehodler token address for specifying eth tokens
  address public ETH_TOKEN_ADDRESS  = address(0x0);
  mapping (uint256 => address) public platforms;
  address bancorLPTokenAddress = 0x48Fb253446873234F2fEBbF9BdeAA72d9d387f94;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
}

    fallback() external payable {
    }



  function lpTolp(uint256 platformFrom, uint256 platformTo, address fromLPByAddress, address[] memory toLPTokensByTokens, uint256 amountFrom) public returns(uint256){

      ERC20 tokenFrom = ERC20(fromLPByAddress);
      tokenFrom.safeTransferFrom(msg.sender, address(this), amountFrom);
      require(platforms[platformFrom] != address(0x0), "The platform does not exist. Was it created by admin with updatePlatforms?");
      wrapper fromWrapper = wrapper(platforms[platformFrom]);
      wrapper toWrapper = wrapper(platforms[platformTo]);
      fromWrapper.unwrap(fromLPByAddress, ETH_TOKEN_ADDRESS, amountFrom);
      uint256 thisETHBalance = address(this).balance;
      (address lpRec,uint256 recAmount)= toWrapper.wrap{value:thisETHBalance}(ETH_TOKEN_ADDRESS, toLPTokensByTokens, thisETHBalance);
      uint256 currentTokenBalance;
      if(platformTo !=3){
          ERC20 tokensRecieved = ERC20(lpRec);
          currentTokenBalance = tokensRecieved.balanceOf(address(this));
          tokensRecieved.safeTransfer(msg.sender, currentTokenBalance );
      }

      else{
          ERC20 tokensRecieved = ERC20(bancorLPTokenAddress);
          currentTokenBalance = tokensRecieved.balanceOf(msg.sender);
      }

      return currentTokenBalance;


  }
    function updateVBNTContract(address newAddress) public onlyOwner returns(bool){
      bancorLPTokenAddress= newAddress;
      return true;
  }


  function updatePlatform(uint256 platformId, address wrapperAddress) public onlyOwner returns(bool){
      platforms[platformId] = wrapperAddress;
      return true;
  }

}
