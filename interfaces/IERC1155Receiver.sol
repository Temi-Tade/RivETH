// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}