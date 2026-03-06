// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract Called {
    uint256 public immutable a = 2;

    function getValue() public pure returns(uint256) {
        return a;
    }
}

contract Caller {
    uint256 public immutable a = 3;
    uint256 public value;

    function getValueDelegate(address called) public {
        (bool success, bytes memory data) = called.delegatecall(
            abi.encodeWithSignature("getValue()")
        );
        if (!success) {
            revert();
        }

        value = abi.decode(data, (uint256));
    }
}