// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "./ERC721.sol";
import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";

contract ERC721Staking is IERC721Receiver {
    constructor (ERC721 _nft) {
        nft = ERC721(_nft);
    }

    ERC721 private nft;

    function onERC721Received(address operator, address from, uint256 id, bytes calldata data ) external returns(bytes4) {
        (operator);
        require(msg.sender == address(nft), "Wrong NFT");
        require(stakes[id].originalOwner == address(0), "Stake already exists");

        uint8 voteId = abi.decode(data, (uint8));
        stakes[id] = Stake({
            voteId: voteId,
            originalOwner: from
        });

        return IERC721Receiver.onERC721Received.selector; // remove this to see if it still works
    }

    struct Stake {
        uint8 voteId;
        address originalOwner;
    }

    mapping(uint256 id => Stake stake) public stakes;

    function withdraw(uint256 id) external {
        require(msg.sender == stakes[id].originalOwner, "Invalid owner");

        delete stakes[id];
        ERC721(nft).safeTransferFrom(address(this), msg.sender, id, abi.encode(0));
        // /try using safe transfer from
    }
}