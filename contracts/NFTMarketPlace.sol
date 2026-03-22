// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {ERC721} from './ERC721.sol';

/// @title A decentralized NFT Market Place
/// @author Temiloluwa Akintade
/// @notice This contract lists NFTs and transfers them if the payment is made
/// @notice payment is mde with native ether but I plan to accept ERC20 equivalents
/// @notice price conversion will be done with chain link price feeds

contract NFTMarketPlace {
    // mint NFT (ERC1721 or 1155)
    // list on marketplace (approve contract, duration)
    // intending buyer makes offer
    // accept exact offer, owner makes choice to accept other offers
    // update listings after sale

    error NFTMarketPlace__TokenIDDoesNotExist(address nft, uint256 tokenId);
    error NFTMarketPlace__TokenOwnerMismtach(address owner, address caller, uint256 tokenId);
    error NFTMarketPlace__ListingExists(address nft, uint256 tokenId);
    error NFTMarketPlace__ListingDoesNotExist();
    error NFTMarketPlace__ApprovalNotGranted(address nft, uint256 tokenId);
    error NFTMarketPlace__SetHigherPrice();
    error NFTMarketPlace__SetDifferentPrice();
    error NFTMarketPlace__BuyFailed();
    error NFTMarketPlace__BuyerIsOwner();
    error NFTMarketPlace__StaleListing(address ownerInContract, address ownerInMarketPlace);

    event List(address indexed nft, address indexed owner, uint256 indexed tokenId, uint256 price);
    event CancelListing(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event BuyItem(address indexed nft, address indexed owner, address indexed buyer, uint256 tokenId, uint256 price);

    ///////////////////////////////////////////////
    /////////// modifiers /////////////////////////
    ///////////////////////////////////////////////
    
    modifier preListingChecks(address _nft, uint256 _tokenId, uint256 _price)  {
        // can only list a token that exists
        if (ERC721(_nft).ownerOf(_tokenId) == address(0)) {
            revert NFTMarketPlace__TokenIDDoesNotExist(_nft, _tokenId);
        }
        // cannot re-list a token
        if (s_listing[_nft][_tokenId].owner == msg.sender) {
            revert NFTMarketPlace__ListingExists(_nft, _tokenId);
        }
        // only owner can list a token
        if (ERC721(_nft).ownerOf(_tokenId) != msg.sender) {
            revert NFTMarketPlace__TokenOwnerMismtach(ERC721(_nft).ownerOf(_tokenId), msg.sender, _tokenId);
        }
        if (!ERC721(_nft).isApprovedForAll(msg.sender, address(this))) {
            // user only needs to approve the collection once
            revert NFTMarketPlace__ApprovalNotGranted(_nft, _tokenId);
        }
        if (_price == 0) {
            revert NFTMarketPlace__SetHigherPrice();
        }
        _;
    }

    modifier modifyLisitingChecks(address _nft,uint256 _tokenId) {
        // listing does not exist
        if (s_listing[_nft][_tokenId].owner == address(0)) {
            revert NFTMarketPlace__ListingDoesNotExist();
        }
        // only owner can edit/cancel a lisitng
        if (s_listing[_nft][_tokenId].owner != msg.sender) {
            revert NFTMarketPlace__TokenOwnerMismtach(ERC721(_nft).ownerOf(_tokenId), msg.sender, _tokenId);
        }
        _;
    }

    modifier buyTokenChecks(address _nft,uint256 _tokenId) {
        address ownerInContract = ERC721(_nft).ownerOf(_tokenId);
        address ownerInMarketPlace = s_listing[_nft][_tokenId].owner;

        // can only buy a token that exists
        if (ownerInContract == address(0)) {
            revert NFTMarketPlace__TokenIDDoesNotExist(_nft, _tokenId);
        }
        if (s_listing[_nft][_tokenId].owner == address(0)) {
            revert NFTMarketPlace__ListingDoesNotExist();
        }
        if (msg.sender == s_listing[_nft][_tokenId].owner) {
            revert NFTMarketPlace__BuyerIsOwner();
        }
        // handle stale listings
        // listings in which the owner has transferred the NFT
        // does this correct the logical flaw in the token contract?
        // use tools like GraphQL to clean them up from the UI
        // can I 
        if (ERC721(_nft).ownerOf(_tokenId) != ownerInMarketPlace) {
            revert NFTMarketPlace__StaleListing(ownerInContract, ownerInMarketPlace);
        }
        _;
    }

    ///////////////////////////////////////////////
    /////////// state variables ///////////////////
    ///////////////////////////////////////////////
    
    struct Listing {
        address nft;
        uint256 tokenId;
        address owner;
        uint256 price;
    }

    // Listing[] private s_listings;
    mapping(address nft => mapping(uint256 tokenId => Listing listing)) private s_listing;
    mapping(address buyer => mapping(uint256 tokenId => uint256 offer)) private s_offer;

    ///////////////////////////////////////////////
    /////////// public functions //////////////////
    ///////////////////////////////////////////////

    /// @notice create a new listing
    /// @param _nft contract address of the NFT
    /// @param _tokenId ID of the NFT
    /// @param _price price of the NFT
    function createListing(address _nft, uint256 _tokenId, uint256 _price) public preListingChecks(_nft, _tokenId, _price) {
        Listing memory new_listing = Listing({
            nft: _nft,
            tokenId: _tokenId,
            owner: msg.sender,
            price: _price
        });

        s_listing[_nft][_tokenId] = new_listing;

        emit List(_nft, msg.sender, _tokenId, _price);
    }

    /// @notice modifying an existing listing
    /// @param _nft contract address of the NFT
    /// @param _tokenId ID of the NFT
    /// @param _newPrice new price of the NFT, should be > current price
    function editListing(address _nft, uint256 _tokenId, uint256 _newPrice) public modifyLisitingChecks(_nft, _tokenId) {
        if (_newPrice == 0) {
            revert NFTMarketPlace__SetHigherPrice(); // this??? should probably get price data from chainlink
        }
        if (_newPrice == s_listing[_nft][_tokenId].price) {
            revert NFTMarketPlace__SetDifferentPrice();
        }

        s_listing[_nft][_tokenId].price = _newPrice;

        emit List(_nft, msg.sender, _tokenId, _newPrice);
    }

    /// @notice cancel a listing
    /// @notice the NFT still exists in the scope of the ERC721 contract, but its listing here is null
    /// @param _nft contract address of the NFT
    /// @param _tokenId ID of the NFT
    function cancelListing(address _nft, uint256 _tokenId) public modifyLisitingChecks(_nft, _tokenId) {
        delete s_listing[_nft][_tokenId];

        emit CancelListing(_nft, msg.sender, _tokenId);
    }

    /// @notice buy a listed NFT
    /// @dev transferFrom is used to transfer the tokens to the receiving address,
    /// approval has been granted when creating the listing
    /// @param _nft contract address of the NFT
    /// @param _tokenId ID of the NFT
    function buyItem(address _nft, uint256 _tokenId) public payable buyTokenChecks(_nft, _tokenId) {
        uint256 amountToPay = msg.value;
        uint256 nftprice = s_listing[_nft][_tokenId].price;
        Listing memory listing = s_listing[_nft][_tokenId];

        if (amountToPay < nftprice) {
            revert NFTMarketPlace__BuyFailed();
        }
        delete s_listing[_nft][_tokenId];

        emit BuyItem(_nft, listing.owner, msg.sender, _tokenId, amountToPay);

        ERC721(_nft).safeTransferFrom(listing.owner, msg.sender, _tokenId, ""); // ignore, linter sees this as 'potential', it is not in actual fact

        (bool success,) = listing.owner.call{value: listing.price}("");
        require(success, "Transfer failed");
    }

    ///////////////////////////////////////////////
    /////////// External view functions ///////////
    ///////////////////////////////////////////////

    function getLisitng(address _nft, uint256 _tokenId) external view returns(Listing memory) {
        return s_listing[_nft][_tokenId];
    }

    function getTokenInformation(address _nft) external view returns(string memory, string memory) {
        ERC721 _token = ERC721(_nft);
        return (_token.name(), _token.symbol());
    }
}