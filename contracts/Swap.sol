// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ERC20 } from "./ERC20.sol";

contract Swap {
    ERC20 public immutable i_token;
    address public immutable i_tokenAddress;

    constructor(address _tokenAddress) payable {
        i_token = ERC20(_tokenAddress);
        i_tokenAddress = _tokenAddress;
    }

    function getBalance(address _owner) public view returns(uint256) {
        return _owner.balance;
    }

    function ethToSend(uint256 _ngncAmount) public pure returns(uint256) {
        uint256 ethUsdPrice = 400000000000 * 1e10;
        uint256 ngncUsdPrice = 150000000000 * 1e10;
        uint256 ngncEthPrice = (ethUsdPrice * ngncUsdPrice) / 1e18; 

        return (_ngncAmount * 1e36) / ngncEthPrice;
    }
    
    function swap(uint256 _amount) public {
        // token contract approves swap contract
        // calculate ETH to get based on NGNC to be swapped
        // call transferFrom to pull NGNC from user
        bool transferFromSuccess = i_token.transferFrom(msg.sender, address(this), _amount);
        require(transferFromSuccess, "Transfer failed");
        // transfer calculated ETH to user
        (bool transferSuccess, ) = payable(msg.sender).call{value: ethToSend(_amount)}("");
        require(transferSuccess, "Transfer failed");
    }
}