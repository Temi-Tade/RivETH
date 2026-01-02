// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC1155Receiver} from "../interfaces/IERC1155Receiver.sol";

contract ERC1155Staking is IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external pure returns(bytes4) {
        operator;
        from;
        tokenId;
        value;
        data;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns(bytes4) {
        operator;
        from;
        tokenIds;
        values;
        data;
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}