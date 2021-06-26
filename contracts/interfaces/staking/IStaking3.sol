// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IStaking3 {
    function exit() external;
    function stake(uint256 amount) external;
    function balanceOf(address who) external view returns (uint256);
}