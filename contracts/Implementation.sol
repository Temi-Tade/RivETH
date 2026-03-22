// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract TransparentProxyImplementation {
    uint256 public number;
    address admin;
    bool initialized;

    constructor() {
        // set to true to LOCK the logic
        initialized = true;
    }

    function initialize() public {
        require(!initialized, "Already initialized");

        initialized = true;
        admin = msg.sender;
    }

    function increment() public {
        number++;
    }
}

contract TransparentProxyImplementationV2 {
    uint256 public number;

    function increment() public {
        number += 2;
    }
}

contract UUPSProxyImplementation {
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    uint256 public number;
    bool initialized;

    constructor() {
        initialized = true;
    }

    function _getAdmin() internal view returns(address admin) {
        assembly {
            admin := sload(ADMIN_SLOT)
        }
    }

    function _setImplementation(address _newImplementation) internal {
        require(_newImplementation != address(0), "zero address");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
    }

    function _authorizeUpgrade() internal view {
        if (_getAdmin() != msg.sender) {
            revert();
        }
    }

    function _upgradeToAndCall(address _newImplementation, bytes memory _data) internal {
        _setImplementation(_newImplementation);
        (bool ok, ) = _newImplementation.delegatecall(_data);
        require(ok, "upgrade error");
    }

    function initialize() public {
        require(!initialized, "Already initialized");

        address admin = msg.sender; 
        assembly {
            sstore(ADMIN_SLOT, admin) // delegatecalled by proxy, stores admin in proxy's slot
        }
        
        initialized = true;
    }

    function increment() public {
        number++;
    }

    function upgradeToAndCall(address _newImplementation, bytes memory _data) public {
        _authorizeUpgrade();
        _upgradeToAndCall(_newImplementation, _data);
    }
}