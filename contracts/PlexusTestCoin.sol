// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PlexusTestCoin is ERC20 {
    using SafeERC20 for ERC20;

    address public owner;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() ERC20("Plexus", "PLX")  {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        
        // mint 100,000 Plexus Coins meant as reward tokens
         _mint(msg.sender, 1000000000000000000000000);
        owner= msg.sender;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("PlexusTestCoin")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function permit(
        address _owner, 
        address _spender, 
        uint _value, 
        uint _deadline, 
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) external {
        require(_deadline >= block.timestamp, "Plexus: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline)
                )
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress == _owner, "ERC20Permit: invalid signature");
        require(recoveredAddress != address(0), "ECDSA: invalid signature");
        _approve(_owner, _spender, _value);
    }
}