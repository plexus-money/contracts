// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IStaking3 {
    function balanceOf(address who) external view returns (uint256);

    // function controller (  ) external view returns ( address );
    
    function exit() external;

    // function lpToken (  ) external view returns ( address );

    function stake(uint256 amount) external;
    // function valuePerShare (  ) external view returns ( uint256 );
}