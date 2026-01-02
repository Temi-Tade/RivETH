// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import { ERC20 } from "./ERC20.sol";

contract TokenShop {
    // receive ETH;
    // get ETH price in USD
    // get NGNC tokens per USD
    // mint NGNC

    ERC20 public immutable i_token;

    constructor(address tokenAddress) {
        i_token = ERC20(tokenAddress);
    }

    error TokenShop_ZeroETHSent();
    error TokenShop_WithdrawError();

    uint256 public ethUsdPrice = 400000000000e10;
    uint256 public ngncUsdPrice = 150000000000e10;

    function amountToMint(uint256 ethAmount) public view returns(uint256) {
        uint256 ethUsd = (ethAmount * ethUsdPrice) / 1e18;
        uint256 ngncUsd = (ethUsd * ngncUsdPrice) / 1e18;

        return ngncUsd;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");

        if (!success) {
            revert TokenShop_WithdrawError();
        }
    }

    receive() external payable {
        if(msg.value == 0) {
            revert TokenShop_ZeroETHSent();
        }

        i_token.mintTokens(msg.sender, amountToMint(msg.value));
    }
}

// 6000000000000000000000000