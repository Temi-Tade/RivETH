// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";
// todo:
// abi encoding of bytes data type in client
// safemint, safe transfer

contract ERC721 {
    mapping(uint256 id => address owner) public ownerOf;
    mapping(address owner => uint256 balance) public balanceOf;
    mapping(address owner => mapping(address operator => bool)) private _isApprovedForAll;
    mapping(uint256 id => address approvedForId) public getApproved;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    function _checkOnERC721Received(
        address from, address to,
        uint256 tokenId, bytes memory data
    ) internal returns(bool) {
        if (address(to).code.length == 0) {
            if (to != address(0)) {
                return true;
            }
        }

        bytes memory callData = abi.encodeWithSelector(0x150b7a02, 
            address(this),
            from,
            tokenId,
            data
        );

        (bool success, bytes memory returnData) = to.call(callData);

        return success && abi.decode(returnData, (bytes4)) == 0x150b7a02;
    }

    function _transfer(address from, address to, uint256 id) internal {
        // place checks, also update approvalforall after a transfer
        ownerOf[id] = to;
        balanceOf[from]--;
        balanceOf[to]++;

        if(getApproved[id] != address(0)) {
            getApproved[id] = address(0);
        }

        emit Transfer(from, to, id);
    }

    function mint(address owner, uint256 id) external virtual {
        require(address(0) == ownerOf[id], "Already minted");

        ownerOf[id] = owner;
        balanceOf[owner] += 1;

        emit Transfer(address(0), owner, id);
    }

    /// @dev can be called by NFT owner/approved operator to move tokens
    // on the owners behalf. This
    function transferFrom(address from, address to, uint256 id) external payable {
        require(ownerOf[id] == msg.sender ||
            _isApprovedForAll[from][msg.sender] ||
            getApproved[id] == msg.sender, "Cannot transfer");

        _transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external payable {
        require(ownerOf[id] == msg.sender ||
            _isApprovedForAll[from][msg.sender] ||
            getApproved[id] == msg.sender, "Cannot transfer");
        
        _transfer(from, to, id);
        bool testBool = _checkOnERC721Received(from, to, id, data);
        require(testBool, "Receiving address cannot handle ERC721 tokens");
    }

    function safeTransferFrom(address from, address to, uint256 id) external payable {
        this.safeTransferFrom(from, to, id);
    }

    function setApprovalForAll(address operator, bool approved) external payable {
        require(address(0) != operator && (operator != msg.sender), "Invaid opearator");
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint256 id) external payable {
        address owner = ownerOf[id];

        require(msg.sender == owner || _isApprovedForAll[owner][msg.sender], "not authorized for this action");
        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function checkOwnership(uint256[] calldata ids, address claimedOwner) external view returns(bool) {
        uint256 owned;

        for(uint256 index = 0; index < ids.length; index++) {
            if (ownerOf[index] == claimedOwner) {
                owned++;
            }
        }

        if (owned == ids.length) {
            return true;
        } else {
            return false;
        }
    }

    // *** getters functions *** //

    function isApprovedForAll(address owner, address operator) external view returns(bool) {
        return _isApprovedForAll[owner][operator];
    }
}