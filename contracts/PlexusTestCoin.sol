// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PlexusTestCoin is ERC20 {
    using SafeERC20 for ERC20;

    address public owner;
    constructor() ERC20("Plexus", "PLX")  {
        // mint 100,000 Plexus Coins meant as reward tokens
         _mint(msg.sender, 1000000000000000000000000);
        owner= msg.sender;
    }
}