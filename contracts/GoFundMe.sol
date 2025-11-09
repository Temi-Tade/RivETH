// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract GoFundMe {
    uint256 public balance;
    address public immutable owner;
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public listOfFunders;
    mapping(address funder => uint256 amount) public fundersToAmount;

    error GoFundMe_BelowMinETH();
    
    constructor() {
        owner = msg.sender;
    }

    function getEthUsdPrice() public pure returns(uint256) {
        return 4000e8 * 1e10;
    }

    function getConversionRate(uint256 _ethAmount) public pure returns(uint256) {
        return (_ethAmount * getEthUsdPrice()) / 1e18;
    }

    function fund() public payable {
        if (getConversionRate(msg.value) < MINIMUM_USD) {
            revert GoFundMe_BelowMinETH();
        }

        listOfFunders.push(msg.sender);
        fundersToAmount[msg.sender] += msg.value;
        balance += msg.value;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
