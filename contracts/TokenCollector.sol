// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC1363} from "./ERC1363.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";

contract TokenCollector is IERC1363Receiver {
    error TokenCollector__WithdrawError();

    event Deposit(address indexed from/*, address indexed beneficiary*/, uint256 value);

    constructor (ERC1363 _token) {
        i_token = _token;
    }

    ERC1363 private immutable i_token;

    mapping(address user => uint256 balance) public balances;

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata /*data*/
    ) external returns(bytes4) {
        require(operator == address(i_token), "Unexpected token");
        
        // address beneficiary;
        // if (data.length == 32) {
        //     beneficiary = abi.decode(data, (address));
        // } else {
        //     beneficiary = from;
        // }

        balances[from] += value;
        emit Deposit(from, value);

        return IERC1363Receiver.onTransferReceived.selector;
    }

    function withdraw(uint256 value) external {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;

        bool success = ERC1363(i_token).transfer(msg.sender, value);
        if (!success) {
            revert TokenCollector__WithdrawError();
        }
    }

    function getAbiEncodedData() external view returns(bytes memory) {
        return abi.encode(address(this));
    }

    function decodeData(bytes memory encodedData) external pure returns(address) {
        return abi.decode(encodedData, (address));
    }
}