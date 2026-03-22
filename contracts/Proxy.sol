// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract TransparentProxy {
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    uint256 public number;
    bool initialized;

    event Upgraded(address indexed newImplementation, address admin);

    constructor(address _logic, bytes memory _data) {
        _setAdmin(msg.sender);
        _setImplementation(_logic);

        if (_data.length > 0) {
            // delegatecall the initialize function in the logic contract
            (bool success, ) = _logic.delegatecall(_data); // can call initialize with params here if owner is not msg.sender at deployment, 
            require(success, "Initialization failed");
        }
    }

    modifier ifAdmin() {
        if (msg.sender == getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function _setImplementation(address _newImplementation) internal {
        require(_newImplementation != address(0), "zero address");

        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
    }

    function _setAdmin(address _newAdmin) internal {
        require(_newAdmin != address(0), "zero address");

        assembly {
            sstore(ADMIN_SLOT, _newAdmin)
        }
    }

    function _fallback() internal {
         assembly {
            calldatacopy(0, 0, calldatasize())
            let result:= delegatecall(gas(), sload(IMPLEMENTATION_SLOT), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function upgradeTo(address _newImplementation) public ifAdmin {
        _setImplementation(_newImplementation);

        emit Upgraded(_newImplementation, msg.sender);
    }

    function changeAdmin(address _newAdmin) public ifAdmin {
        _setAdmin(_newAdmin);
    }

    function getImplementation() external view returns(address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }

    function getAdmin() public view returns(address admin) {
        assembly {
            admin := sload(ADMIN_SLOT)
        }
    }

    fallback() external payable {
       _fallback();
    }

    receive() external payable{
        _fallback();
    }
}

contract UUPSProxy {
    // this contract should inherit UUPSUpgradeable

    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    uint256 public number;
    bool initialized;

    constructor(address _logic, bytes memory _data) {
        _setImplementation(_logic);

        if (_data.length > 0) {
            (bool ok, ) = _logic.delegatecall(_data);
            require(ok, "Initialization failed"); // never ignore this!
        }
    }

    function _setImplementation(address _newImplementation)  internal {
        require(_newImplementation != address(0), "Cannot implement zero address");

        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
    }

    function _delegate() internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), sload(IMPLEMENTATION_SLOT), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }
}

contract UpgradeableBeacon {
    address public implementation;
    address public owner;

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    function upgradeTo(address _newImplementation) public {
        require(msg.sender == owner, "not owner");

        implementation = _newImplementation;
    }
}

contract BeaconProxy {
    uint256 public number;
    address beacon; // in prod, store in eip1967 slots
    
    constructor(address _beacon) {
        beacon = _beacon;
    }

    function _fallback() internal {
        address implementation = UpgradeableBeacon(beacon).implementation();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}