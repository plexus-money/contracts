// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./IWrapper.sol";
interface IRemix {

   function createWrap(
        IWrapper.WrapParams memory params,
        bool remixing
    )
        external
        payable
        returns (address,uint256);

}  
