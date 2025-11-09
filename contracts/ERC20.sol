// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract ERC20 {
    string public name;
    string public symbol;
    address public owner;
    uint256 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error Mint_NotOwner();
    error Transfer_NotEnoughTokens();
    error TransferFrom_NotEnoughAllowance();

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol) payable {
        name = _name;
        symbol = _symbol;

        owner = msg.sender;
        decimals = 18;
    }

    // 1000000000000000000

    function mint(address to, uint256 amount) public onlyOwner {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(address to, uint256 amount) public returns(bool) {
        if (balanceOf[msg.sender] < amount) {
            revert Transfer_NotEnoughTokens();
        }

        balanceOf[to] += amount;
        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool) {
        if (balanceOf[msg.sender] < amount) {
            revert Transfer_NotEnoughTokens();
        }

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        if (msg.sender == owner) {
            balanceOf[owner] -= amount;
            balanceOf[to] += amount;
        } else {
            if (allowance[from][msg.sender] < amount) {
                revert TransferFrom_NotEnoughAllowance();
            } 

            balanceOf[from] -= amount;
            balanceOf[to] += amount;
            allowance[from][msg.sender] -= amount;
            emit Transfer(from, to, amount);
        }

        return true;
    }
    // 500000000000000000

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Mint_NotOwner();
        }
        _;
    }
}
