// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract GoFundMe {
    uint256 public balance;
    address public immutable owner;
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public listOfFunders;
    mapping(address funder => uint256 amount) public fundersToAmount;

    error GoFundMe__BelowMinETH();
    error GoFundMe__NotOwner();
    error GoFundMe__WithdrawError();
    error GoFundMe__ZeroBalanceError();
    
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
            revert GoFundMe__BelowMinETH();
        }

        listOfFunders.push(msg.sender);
        fundersToAmount[msg.sender] += msg.value;
        balance += msg.value;
    }

    function withdraw() public onlyOwner returns (bool) {
        /* 
        - set balances to zero
        - withdraw
        - return true on success
        */
        uint256 contractBalance = uint256(address(this).balance);
        if (contractBalance == 0) {
            revert GoFundMe__ZeroBalanceError();
        }
        
        (bool success, ) = msg.sender.call{value: contractBalance}("");
        if (!success) {
            revert GoFundMe__WithdrawError();
        }

        listOfFunders = new address[](0);

        return true;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert GoFundMe__NotOwner(); 
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
