// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC1363} from "./ERC1363.sol";
import {IERC1363Spender} from "../interfaces/IERC1363Spender.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";

contract Router is IERC1363Spender {
    mapping(address token => bool approval) isApprovedToken;

    function getTarget(bytes memory _data) internal pure returns(address) {
        return abi.decode(_data, (address));
    }

    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns(bytes4) {
        require(isApprovedToken[msg.sender], "Not an approved token");
        address target = getTarget(data);
        bool success = ERC1363(msg.sender).transferFrom(owner, target, value);
        require(success, "Transfer failed");

        // `target` is a contract
        if (target.code.length > 0) {
            bytes4 returnData = IERC1363Receiver(target).onTransferReceived(msg.sender, owner, value, data);
            require(returnData == IERC1363Receiver.onTransferReceived.selector, "Receiving address cannot handle ERC20 tokens.");
        }

        return IERC1363Spender.onApprovalReceived.selector;
    }

    function approveToken(address _tokenAddress, bool approval) public {
        isApprovedToken[_tokenAddress] = approval;
    }
}