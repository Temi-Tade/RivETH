// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "./ERC721.sol";

contract ERC721Enumerable is ERC721 {
    error ERC721Enumerable__OutOfBoundsIndex(address, uint256);

    constructor() ERC721("", "") {
        
    }

    mapping(address owner => mapping(uint256 index => uint256)) private _ownedTokens; // returns a tokenId within a `balanceOf` range of NFTs for an `owner`
    mapping(uint256 tokenId => uint256) private _ownedTokensIndex; // returns the index of an owned tokenId for an `owner`
    uint256[] private _allTokens; // all NFTs in contract
    mapping(uint256 tokenId => uint256) private _allTokensIndex; // index of tokenId in _allTokens

    function totalSupply() public view returns(uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns(uint256) {
        if (index > totalSupply()) {
            revert ERC721Enumerable__OutOfBoundsIndex(address(0), index);
        }
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns(uint256) {
        if (index > totalSupply()) {
            revert ERC721Enumerable__OutOfBoundsIndex(address(0), index);
        }
        return _ownedTokens[owner][index];
    }

    // function mint(address owner, uint256 tokenId) public override {
    //     uint256 tokenIndex = totalSupply() - 1;
    //     if () {

    //     }

    //     _allTokens.push(tokenId);
    //     _allTokensIndex[tokenIndex] = tokenId;
    //     _ownedTokens[owner][tokenIndex] = tokenId;
    //     _ownedTokensIndex[tokenIndex] = tokenId;
    // }
}