// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/token/IERC20Permit.sol";
import "../proxyLib/OwnableUpgradeable.sol";

contract Airdrop is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Permit;

    address public tokenAddress;
    uint256 public standardAmount; // Default 4000
    uint256 public blocksForEpoch; // Default 50
    mapping(address => uint256) public amounts;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public blockNumbers;

    constructor() payable {}

    fallback() external payable {}

    receive() external payable {}

    function initialize(address _tokenAddress, address[] memory _addresses)
        external
        initializeOnceOnly
    {
        require(_tokenAddress != address(0x0), "The token does not exist.");
        tokenAddress = _tokenAddress;
        standardAmount = 4000 * 10**18;
        blocksForEpoch = 50;
        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            amounts[_addresses[i]] = standardAmount;
            balanceOf[_addresses[i]] = standardAmount;
        }
    }

    function addAirdropAddress(address _address) external onlyOwner {
        require(_address != address(0x0), "The address does not exist.");
        amounts[_address] = standardAmount;
        balanceOf[_address] = standardAmount;
    }

    function setStandardAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "The amount is not greater than zero.");
        standardAmount = _amount;
    }

    function setAmount(address _address, uint256 _amount) external onlyOwner {
        require(
            amounts[_address] > 0,
            "The address does not exists in the address array."
        );
        require(_amount > 0, "The amount is not greater than zero.");
        amounts[_address] = _amount;
        balanceOf[_address] = _amount;
    }

    function claimAirdropWithOption1() external {
        require(
            amounts[msg.sender] > 0,
            "The address does not exists in the address array."
        );

        IERC20Permit token = IERC20Permit(tokenAddress);

        require(balanceOf[msg.sender] != 0, "You already got the airdrop");

        uint256 upfrontAmount = amounts[msg.sender].mul(4).div(10);

        token.safeTransfer(msg.sender, upfrontAmount);

        balanceOf[msg.sender] = 0;
    }

    function claimAirdropWithOption1WithPermit(
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            amounts[msg.sender] > 0,
            "The address does not exists in the address array."
        );

        IERC20Permit token = IERC20Permit(tokenAddress);

        require(balanceOf[msg.sender] != 0, "You already got the airdrop");

        uint256 upfrontAmount = amounts[msg.sender].mul(4).div(10);
        uint256 value = approveMax ? type(uint256).max : upfrontAmount;

        token.permit(msg.sender, address(this), value, deadline, v, r, s);
        token.safeTransfer(msg.sender, upfrontAmount);

        balanceOf[msg.sender] = 0;
    }

    function claimAirdropWithOption2() external {
        require(
            amounts[msg.sender] > 0,
            "The address does not exists in the address array."
        );
        require(balanceOf[msg.sender] != 0, "You already got the airdrop");

        IERC20Permit token = IERC20Permit(tokenAddress);

        if (balanceOf[msg.sender] == amounts[msg.sender]) {
            uint256 upfrontAmount = amounts[msg.sender].mul(3).div(10);
            token.safeTransfer(msg.sender, upfrontAmount);
            blockNumbers[msg.sender] = block.number;
            balanceOf[msg.sender] -= upfrontAmount;
        } else {
            uint256 epochs = block.number.sub(blockNumbers[msg.sender]).div(
                blocksForEpoch
            );

            if (epochs > 7) epochs = 7;

            require(epochs > 0, "You need to wait more time.");

            uint256 amount = amounts[msg.sender].mul(epochs + 3).div(10).sub(
                amounts[msg.sender].sub(balanceOf[msg.sender])
            );
            token.safeTransfer(msg.sender, amount);
            balanceOf[msg.sender] -= amount;
        }
    }

    function claimAirdropWithOption2WithPermit(
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            amounts[msg.sender] > 0,
            "The address does not exists in the address array."
        );
        require(balanceOf[msg.sender] != 0, "You already got the airdrop");

        IERC20Permit token = IERC20Permit(tokenAddress);

        if (balanceOf[msg.sender] == amounts[msg.sender]) {
            uint256 upfrontAmount = amounts[msg.sender].mul(3).div(10);
            uint256 value = approveMax ? type(uint256).max : upfrontAmount;
            token.permit(msg.sender, address(this), value, deadline, v, r, s);
            token.safeTransfer(msg.sender, upfrontAmount);
            blockNumbers[msg.sender] = block.number;
            balanceOf[msg.sender] -= upfrontAmount;
        } else {
            uint256 epochs = block.number.sub(blockNumbers[msg.sender]).div(
                blocksForEpoch
            );

            if (epochs > 7) epochs = 7;

            require(epochs > 0, "You need to wait more time.");

            uint256 amount = amounts[msg.sender].mul(epochs + 3).div(10).sub(
                amounts[msg.sender].sub(balanceOf[msg.sender])
            );
            uint256 value = approveMax ? type(uint256).max : amount;
            token.permit(msg.sender, address(this), value, deadline, v, r, s);
            token.safeTransfer(msg.sender, amount);
            balanceOf[msg.sender] -= amount;
        }
    }
}
