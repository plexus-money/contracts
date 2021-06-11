// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Upgradeable {
    address _dest;
    address payable public owner;
    function initialize() virtual public;
    
    function replace(address target) public {
        _dest = target;
        target.delegatecall(abi.encodeWithSelector(bytes4(keccak256("initialize()"))));
    }
}

contract Dispatcher is Upgradeable {
    constructor (address target) {
        replace(target);
        owner = msg.sender;
    }
    
    function initialize() override public{
        // Should only be called by on target contracts, not on the dispatcher
        assert(false);
    }

    fallback() external {
        address _impl = _dest;
        require(_impl != address(0));
    
        assembly {
          let ptr := mload(0x40)
          calldatacopy(ptr, 0, calldatasize())
          let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
          let size := returndatasize()
          returndatacopy(ptr, 0, size)
    
          switch result
          case 0 { revert(ptr, size) }
          default { return(ptr, size) }
        }
    }
}