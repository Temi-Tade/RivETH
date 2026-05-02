// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

/// @title Book contract
/// @author Temiloluwa Akintade
/// @notice A decentralized system in which once deployed allows authors to have their books on chain
/// @notice these books can be minted (bought) at a price or borrowed by locking an amount that will be returned when the book is sent back to the contract
/// @notice books can be transferred, listed on marketplaces and sold, author receives royalties from sales

import {ERC721} from "./ERC721.sol";

contract Book is ERC721 {
    address private author;

    uint64 private immutable i_maxSupply;
    uint256 private constant BOOK_PRICE = 0.01 ether; // use chainlink to get USD equivalent so book price is stable

    error Book__SendMoreETH();

    // royalte fee %
    // can buy more than one book at once? loops? ERC1155?
    // borrow book
    // can author address change?
    // price checks for borrowers, in case ETH tanks

    constructor(
        uint64 _maxSupply
        /*address _author,*/
    ) ERC721("Oxford Handbook of Clinical Pathology", "OXFORDPATH   ", "ipfs://QmP8YCWA3WxtK9kjQBF2LDjFWF5ffvbSgYK4S4yfuVgWES") {
        i_maxSupply = _maxSupply;
        author = msg.sender;
    }

    function buyBook() public payable {
        if (msg.value != BOOK_PRICE) {
            revert Book__SendMoreETH();
        }
        mintNft(msg.sender);
    }
}
