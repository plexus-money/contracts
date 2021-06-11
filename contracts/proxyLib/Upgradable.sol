// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

interface UpgradableInterface {
    function componentUid() external returns(bytes32);
}

contract Upgradable {
    
    bool directCall = true;
    bytes32 internal COMPONENT_UID;
    
    modifier onlyProxy {
        require(!directCall);
        _;
    }
    constructor(bytes32 componentUid) public {
        COMPONENT_UID = componentUid;
    }
    
    function componentUid() public view returns(bytes32) {
        return COMPONENT_UID;
    }
    
}
