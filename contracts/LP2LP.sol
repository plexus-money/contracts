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



pragma solidity 0.7.4;


interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



interface wrapper{
    function wrap(address sourceToken, address[] memory destinationTokens, uint256 amount) external payable returns(address, uint256);
    function unwrap(address sourceToken, address destinationToken, uint256 amount) external payable returns( uint256);
}




library SafeMath {
  function mul(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }



  function sub(uint256 a, uint256 b) internal view returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal view returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

library SafeERC20 {
  using SafeMath for uint256;
    
  function safeTransfer(
    ERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value), 
    "You must approve this contract or have enough tokens to do this conversion");
  }

  function safeApprove(
    ERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }
  
  function safeIncreaseAllowance(
    ERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }
  
  function safeDecreaseAllowance(
    ERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
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
