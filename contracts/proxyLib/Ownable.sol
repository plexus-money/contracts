pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * @author https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**set
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
          require(newOwner != address(0));
          emit OwnershipTransferred(owner, newOwner);
          owner = newOwner;
    }

}
