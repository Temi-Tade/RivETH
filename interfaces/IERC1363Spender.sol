// SPDX-License-Identifier: MIT
pragma solidity 0.8.36;

interface IERC1363Spender {
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns(bytes4);
}