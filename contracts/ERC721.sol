// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC721Receiver} from "../interfaces/IERC721Receiver.sol";
// todo:
// abi encoding of bytes data type in client
// safemint, safe transfer

contract ERC721 {
    string public name;
    string public symbol;
    uint256 private s_tokenCounter;
    mapping(uint256 id => address owner) public ownerOf;
    mapping(address owner => uint256 balance) public balanceOf;
    mapping(uint256 id => address approvedForId) public getApproved;

    mapping(uint256 tokenId => string tokenUri) private s_tokenUri;
    mapping(address owner => mapping(address operator => bool)) private _isApprovedForAll;

    string private constant TOKEN_URI = "ipfs://QmP8YCWA3WxtK9kjQBF2LDjFWF5ffvbSgYK4S4yfuVgWES";

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function _checkOnERC721Received(
        address from, address to,
        uint256 tokenId, bytes memory data
    ) internal returns(bool) {
        // if (address(to).code.length == 0) {
        //     revert();
        //     // if (to != address(0)) {
        //     //     return true;
        //     // }
        // }

        bytes memory callData = abi.encodeWithSelector(0x150b7a02, 
            address(this),
            from,
            tokenId,
            data
        );

        (bool success, bytes memory returnData) = to.call(callData);

        return success && abi.decode(returnData, (bytes4)) == 0x150b7a02;
    }

    function _mint(address receipient) internal {
        require(address(0) == ownerOf[s_tokenCounter], "Already minted");

        ownerOf[s_tokenCounter] = receipient;
        balanceOf[receipient] += 1;
        s_tokenUri[s_tokenCounter] = TOKEN_URI;
        s_tokenCounter++;

        emit Transfer(address(0), receipient, s_tokenCounter);
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

    function _safeMint(address receipient) internal {
        _mint(receipient);

        if (receipient.code.length > 0) {
            bool ok = _checkOnERC721Received(address(this), receipient, s_tokenCounter, abi.encode(s_tokenCounter));
            require(ok, "Receipient Cannot Handle ERC721");
        }
    }

    function mintNft(address receipient) external {
        _safeMint(receipient);
    }

    /// @dev can be called by NFT owner/approved operator to move tokens
    // on the owners behalf. This
    function transferFrom(address from, address to, uint256 id) public payable {
        require(ownerOf[id] == msg.sender ||
            _isApprovedForAll[from][msg.sender] ||
            getApproved[id] == msg.sender, "Cannot transfer");

        _transfer(from, to, id);
    }

    /**
    ** @dev safeTransferFrom should only be used when the receipient
    ** is a contract, if the receipient is an EOA, use tranferFrom, this
    ** saves gas.
    */
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public payable {
        // require(address(to).code.length > 0, "Receiver can handle ERC721");
        require(ownerOf[id] == msg.sender ||
            _isApprovedForAll[from][msg.sender] ||
            getApproved[id] == msg.sender, "Cannot transfer");
        
        _transfer(from, to, id);

        if (address(to).code.length > 0) {
            bool testBool = _checkOnERC721Received(from, to, id, data);
            require(testBool, "Receiving address cannot handle ERC721 tokens");
        }
    }

    function safeTransferFrom(address from, address to, uint256 id) public payable {
        this.safeTransferFrom(from, to, id);
    }

    function setApprovalForAll(address operator, bool approved) public payable {
        require(address(0) != operator && (operator != msg.sender), "Invaid opearator");
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint256 id) public payable {
        address owner = ownerOf[id];

        require(msg.sender == owner || _isApprovedForAll[owner][msg.sender], "not authorized for this action");
        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    // *** getters functions *** //
    function checkOwnership(uint256[] calldata ids, address claimedOwner) external view returns(bool) {
        uint256 owned;

        for(uint256 index = 0; index < ids.length; index++) {
            if (ownerOf[ids[index]] == claimedOwner) {
                owned++;
            }
        }

        if (owned == ids.length) {
            return true;
        } else {
            return false;
        }
    }

    function isApprovedForAll(address owner, address operator) external view returns(bool) {
        return _isApprovedForAll[owner][operator];
    }

    function tokenURI(uint256 tokenId) external view returns(string memory) {
        return s_tokenUri[tokenId];
    }
}