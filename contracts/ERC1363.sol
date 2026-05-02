// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "./ERC20.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";
import {IERC1363Spender} from "../interfaces/IERC1363Spender.sol";

contract ERC1363 is ERC20 {
    error ERC1363__TransferFailed();
    error ERC1363__TransferFromFailed();
    error ERC1363__EOAReceiver(address);
    error ERC1363__InvalidReceiver(address);
    error ERC1363__ApprovalFailed(address, uint256);
    error ERC1363__ApprovalHandleError(address, uint256);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function _checkOnTransferReceived(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) private {
        if (address(to).code.length == 0) {
            revert ERC1363__EOAReceiver(to);
        }

        try IERC1363Receiver(to).onTransferReceived(msg.sender, from, value, data) returns(bytes4 returnData) {
            if (returnData != IERC1363Receiver.onTransferReceived.selector) {
                revert ERC1363__InvalidReceiver(to);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC1363__InvalidReceiver(to);
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
    * @notice Check if Router has been approved to transfer ERC1363 tokens
    * @dev Call to check if Router has approved the ERC1363 contract before performing the actual transfer
    * @param spender Router Address
    **/
    function _checkOnApprovalReceived(
        address spender,
        uint256 value,
        bytes memory data 
    ) private {
        try IERC1363Spender(spender).onApprovalReceived(msg.sender, value, data) returns(bytes4 returnData) {
            if (returnData != IERC1363Spender.onApprovalReceived.selector) {
                revert ERC1363__ApprovalHandleError(spender, value);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC1363__ApprovalHandleError(spender, value);
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function transferAndCall(address to, uint256 value) public returns(bool) {
        if (!transfer(to, value)) {
            revert ERC1363__TransferFailed();
        }

        _checkOnTransferReceived(msg.sender, to, value, "");
        return true;
    }

    function transferAndCall(
        address to, 
        uint256 value,
        bytes calldata data
    ) public returns(bool) {
        if (!transfer(to, value)) {
            revert ERC1363__TransferFailed();
        }

        _checkOnTransferReceived(msg.sender, to, value, data);
        return true;
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) public returns(bool) {
        // call ERC20 standard transferFrom
        if (!transferFrom(from, to, value)) {
            revert ERC1363__TransferFromFailed();
        }

        // call _checkOnTransferReceived to check if
        // receiving contract can receive tokens
        _checkOnTransferReceived(from, to, value, "");
        return true;
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) public returns(bool) {
        if (!transferFrom(from, to, value)) {
            revert ERC1363__TransferFromFailed();
        }

        _checkOnTransferReceived(from, to, value, data);
        return true;
    }

    function approveAndCall(address spender, uint256 value) public returns(bool) {
        return approveAndCall(spender, value, "");
    }

    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) public returns(bool) {
        if (!approve(spender, value)) {
            revert ERC1363__ApprovalFailed(spender, value);
        }

        _checkOnApprovalReceived(spender, value, data);
        return true;
    }
}