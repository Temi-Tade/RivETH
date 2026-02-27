// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;


contract ERC1155 {
    // ---- errors ---- //
    error ERC1155__ApprovalError();
    error ERC1155__TransferError();
    error ERC1155__BatchError();
    // error name(type name );

    // ---- events ---- //
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] tokenIds,
        uint256[] values
    );
    event URI(string, uint256 indexed); //

    // ---- private variables ---- //
    mapping(uint256 id => mapping(address owner => uint256 balance)) private _balances;
    mapping(address owner => mapping(address opeartor => bool approval)) private _isApprovedForAll;

    // ---- internal functions ----//
    function _transfer(address from, address to, uint256 tokenId, uint256 value) internal {
        if (_balances[tokenId][from] < value) {
            revert ERC1155__TransferError();
        }

        _balances[tokenId][from] -= value;
        _balances[tokenId][to] += value;

        emit TransferSingle(msg.sender, from, to, tokenId, value);
    }

    function _createTokenId(uint256 collectionId, uint256 itemId) internal pure returns(bytes32) {
        return bytes32((collectionId << 128) + itemId);
    }

    function _checkOnERC1155Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) internal returns(bool) {
        if (address(to).code.length == 0) {
            if (to != address(0)) {
                return true;
            }
        }

        bytes memory callData = abi.encodeWithSelector(0xf23a6e61,
            address(this),
            from,
            tokenId,
            value,
            data
        );

        (bool ok, bytes memory returnData) = address(to).call(callData);
        return (ok && abi.decode(returnData, (bytes4)) == 0xf23a6e61);
    }

    function _checkOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes memory data
    ) internal  returns(bool) {
        if (address(to).code.length == 0) {
            if (to != address(0)) {
                return true;
            }
        }

        bytes memory callData = abi.encodeWithSelector(0xbc197c81,
            msg.sender,
            from,
            tokenIds,
            values,
            data
        );

        (bool ok, bytes memory returnData) = address(to).call(callData);
        return(ok && abi.decode(returnData, (bytes4)) == 0xbc197c81);
    }

    // ---- external functions ---- //
    function balanceOf(address owner, uint256 tokenId) external view returns(uint256) {
        return _balances[tokenId][owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns(uint256[] memory) {
        /// @param _owners an array of addresses
        /// @param _ids an array of tokenIds
        /// @return uint256[] an array of _balances of a token at index X held by an address at index X

        if (_ids.length != _owners.length) {
            revert ERC1155__BatchError();
        }

        uint256[] memory tokensPerOwner = new uint256[](_owners.length);

        for (uint256 ownerIndex = 0; ownerIndex < _owners.length; ownerIndex++) {
            tokensPerOwner[ownerIndex] = this.balanceOf(_owners[ownerIndex], _ids[ownerIndex]);
        }

        return tokensPerOwner;
    }

    function mintNFT(address owner, uint256 tokenId, uint256 value) external payable {
        // should i set params as collection and item id rather than token id???!!!
        _balances[tokenId][owner] += value;

        emit TransferSingle(msg.sender, address(0), owner, tokenId, value);
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == address(0) || msg.sender == operator) {
            revert ERC1155__ApprovalError();
        }
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external payable {
        if (msg.sender != from) {
            if (!_isApprovedForAll[from][msg.sender]) {
                revert ERC1155__TransferError();
            }
        }

        _transfer(from, to, id, value);
        bool success = _checkOnERC1155Received(from, to, id, value, data);
        require(success, "Receiving address cannot handle ERC1155 tokens.");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external payable {
        if (msg.sender != from) {
            if (!_isApprovedForAll[from][msg.sender]) {
                revert ERC1155__TransferError();
            }
        } // put this check inside a function

        if (ids.length != values.length) {
            revert ERC1155__BatchError();
        }

        uint256 iterations = ids.length;

        address[] memory owners = new address[](iterations);
        for (uint256 i = 0; i < iterations; i++) {
            owners[i] = from;
        }

        uint256[] memory currentBalances = this.balanceOfBatch(owners, ids);
        for (uint256 i = 0; i < iterations; i++) {
            require(currentBalances[i] >= values[i], "Insufficient funds");
        }

        for (uint256 index = 0; index < ids.length; index++) {
            _transfer(from, to, ids[index], values[index]);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        bool success = _checkOnERC1155BatchReceived(from, to, ids, values, data);
        require(success, "Receiving address cannot handle ERC1155 tokens");

    }

    // ----getters---- //
    function isApprovedForAll(address owner, address operator) external view returns(bool) {
        return _isApprovedForAll[owner][operator];
    }

    function getTokenId(uint256 collectionId, uint256 itemId) external pure returns(bytes32) {
        return _createTokenId(collectionId, itemId);
    }

    function getCollectionAndItemId(uint256 tokenId) external pure returns(uint256, uint256) {
        uint256 _collectionId = tokenId>>128;
        uint256 _itemId = uint128(tokenId);

        return (_collectionId, _itemId);
    }
}