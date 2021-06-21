// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlexusTestCoin is ERC20 {

    address public owner;
    constructor() ERC20("Plexus", "PLX")  {
        // mint 100,000 Plexus Coins meant as reward tokens
         _mint(msg.sender, 1000000000000000000000000);
        owner= msg.sender;
    }
}