// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./OwnableProxied.sol";
import "./OwnableUpgradeable.sol";

contract OwnableProxy is OwnableProxied {
    /*
     * @notice Constructor sets the target and emmits an event with the first target
     * @param _target - The target Upgradeable contracts address
     */
    address public deployer;

    constructor(address _target) {
        deployer = msg.sender;
        upgradeTo(_target);
    }

    /*
     * @notice Fallback function that will execute code from the target contract to process a function call.
     * @dev Will use the delegatecall opcode to retain the current state of the Proxy contract and use the logic
     * from the target contract to process it.
     */
    fallback() external payable {
        bytes memory data = msg.data;
        address impl = target;

        assembly {
            let result := delegatecall(
                gas(),
                impl,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}

    modifier onlyDeployer() {
        require(msg.sender == deployer, "");
        _;
    }

    function setDeployer(address _deployer) public onlyOwner {
        deployer = _deployer;
    }

    /*
     * @notice Upgrades the contract to a different target that has a changed logic. Can only be called by owner
     * @dev See https://github.com/jackandtheblockstalk/upgradeable-proxy for what can and cannot be done in Upgradeable
     * contracts
     * @param _target - The target Upgradeable contracts address
     */
    function upgradeTo(address _target) public override onlyDeployer {
        assert(target != _target);

        address oldTarget = target;
        target = _target;

        emit EventUpgrade(_target, oldTarget, msg.sender);
    }

    /*
     * @notice Performs an upgrade and then executes a transaction. Intended use to upgrade and initialize atomically
     */
    //     function upgradeTo(address _target, bytes memory _data) public onlyOwner {
    //         upgradeTo(_target);
    //         assert(target.delegatecall(_data));
    //     }
}
