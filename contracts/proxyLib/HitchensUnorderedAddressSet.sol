// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

library HitchensUnorderedAddressSetLib {
    
    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }
    
    function insert(Set storage self, address key) internal {
        require(!exists(self, key), "UnorderedAddressSet(101) - Address (key) already exists in the set.");
        self.keyPointers[key] = self.keyList.push(key)-1;
    }
    
    function remove(Set storage self, address key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Address (key) does not exist in the set.");
        address keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.length--;
    }
    
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
    
    function keyAtIndex(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }
    
    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}
