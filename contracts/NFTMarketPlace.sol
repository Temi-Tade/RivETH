// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {ERC721} from './ERC721.sol';

contract NFTMarketPlace {
    // mint NFT (ERC1721 or 1155)
    // list on marketplace (approve contract, )
    // intending buyer makes offer
    // accept exact offer, owner makes choice to accept other offers
    // update listings after sale

    error NFTMarketPlace__TokenIDDoesNotExist(address nft, uint256 tokenId);
    error NFTMarketPlace__TokenOwnerMismtach(address owner, address caller, uint256 tokenId);
    error NFTMarketPlace__ListingExists(address nft, uint256 tokenId);
    error NFTMarketPlace__ListingDoesNotExisit();
    error NFTMarketPlace__ApprovalNotGranted(address nft, uint256 tokenId);
    error NFTMarketPlace__SetHigherFloorPrice();
    
    struct Listing {
        address nft;
        uint256 tokenId;
        address owner;
        uint256 floorPrice;
    }

    Listing[] private s_listings;
    mapping(address nft => mapping(uint256 tokenId => uint256 index)) private s_listingMap; // track the listings

    mapping(address nft => mapping(uint256 tokenId => Listing listing)) private s_lisitng;
    mapping(address buyer => mapping(uint256 tokenId => uint256 offer)) private s_offer;

    function createListing(address _nft, uint256 _tokenId, uint256 _floorPrice) public {
        // can only list a token that exists
        if (ERC721(_nft).ownerOf(_tokenId) == address(0)) {
            revert NFTMarketPlace__TokenIDDoesNotExist(_nft, _tokenId);
        }
        // can only list a token you own
        if (ERC721(_nft).ownerOf(_tokenId) != msg.sender) {
            revert NFTMarketPlace__TokenOwnerMismtach(ERC721(_nft).ownerOf(_tokenId), msg.sender, _tokenId);
        }
        // cannot re-list a token
        if (s_lisitng[_nft][_tokenId].owner == msg.sender) {
            revert NFTMarketPlace__ListingExists(_nft, _tokenId);
        }
        if (!ERC721(_nft).isApprovedForAll(msg.sender, address(this))) {
            revert NFTMarketPlace__ApprovalNotGranted(_nft, _tokenId);
        }

        Listing memory new_listing = Listing({
            nft: _nft,
            tokenId: _tokenId,
            owner: msg.sender,
            floorPrice: _floorPrice
        });

        s_listingMap[_nft][_tokenId] = s_listings.length;
        s_lisitng[_nft][_tokenId] = new_listing;
        s_listings.push(new_listing);

        // set approval
        // delegatecall
        // (bool ok, ) = _nft.call(abi.encodeWithSignature("setApprovalForAll(address,bool)", address(this), true));
        // require(ok, "Lisitng Creation failed");
    }

    function editListing(address _nft, uint256 _tokenId, uint256 _newFloorPrice) public {
        // listing does not exisit
        if (s_lisitng[_nft][_tokenId].owner == address(0)) {
            revert NFTMarketPlace__ListingDoesNotExisit();
        }
        // only owner can edit a lisitng
        if (s_lisitng[_nft][_tokenId].owner != msg.sender) {
            revert NFTMarketPlace__TokenOwnerMismtach(ERC721(_nft).ownerOf(_tokenId), msg.sender, _tokenId);
        }
        // new FP should be > current FP
        if (_newFloorPrice <= s_lisitng[_nft][_tokenId].floorPrice) {
            revert NFTMarketPlace__SetHigherFloorPrice(); // this??? should probably get price data from chainlink
        }

        // edit from listing map
        uint256 listing_index = s_listingMap[_nft][_tokenId];
        s_listings[listing_index].floorPrice = _newFloorPrice;
        s_lisitng[_nft][_tokenId].floorPrice = _newFloorPrice;
    }

    function cancelListing(address _nft, uint256 _tokenId) public {
        // listing does not exisit
        if (s_lisitng[_nft][_tokenId].owner == address(0)) {
            revert NFTMarketPlace__ListingDoesNotExisit();
        }
        // only owner can cancel a lisitng
        if (s_lisitng[_nft][_tokenId].owner != msg.sender) {
            revert NFTMarketPlace__TokenOwnerMismtach(ERC721(_nft).ownerOf(_tokenId), msg.sender, _tokenId);
        }

        // array shift
        uint256 index = s_listingMap[_nft][_tokenId];
        uint256 lastIndex = s_listings.length - 1;

        s_listings[index] = s_listings[lastIndex];
        s_listings.pop();
        delete s_lisitng[_nft][_tokenId];
        s_listingMap[_nft][_tokenId] = 0;
    }

    // getters
    function getLisitng(address _nft, uint256 _tokenId) external view returns(Listing memory) {
        return s_lisitng[_nft][_tokenId];
    }
}