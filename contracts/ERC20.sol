// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract ERC20 {
    error ERC20__NotOwner();
    error ERC20__NotEnoughTokens();
    error ERC20__NotEnoughAllowance();
    error ERC20__InvalidSpender();

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string public name;
    string public symbol;
    address public owner;
    uint256 public totalSupply;

    uint8 public immutable decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isMinter;


    constructor(string memory _name, string memory _symbol) payable {
        name = _name;
        symbol = _symbol;

        owner = msg.sender;
        decimals = 18;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (balanceOf[from] < amount) {
            revert ERC20__NotEnoughTokens();
        }

        balanceOf[to] += amount;
        balanceOf[from] -= amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        // handle zeros
        if (balanceOf[from] < amount) {
            revert ERC20__NotEnoughTokens();
        }

        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    // ---- external functions ---- //
    function mintTokens(address to, uint256 amount) external /*onlyOwner*/ {
        _mint(to, amount);
    }

    function whiteListMinter(address minter) external /*onlyOwner*/ {
        isMinter[minter] = true;
    }

    function transfer(address to, uint256 amount) public returns(bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool) {
        if (balanceOf[msg.sender] < amount) {
            revert ERC20__NotEnoughTokens();
        }
        if (spender == address(0) || spender == msg.sender) {
            revert ERC20__InvalidSpender();
        }

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        if (msg.sender == from) {
            // balanceOf[from] -= amount;
            // balanceOf[to] += amount;
            _transfer(from, to, amount);
        } else {
            if (allowance[from][msg.sender] < amount) {
                revert ERC20__NotEnoughAllowance();
            } 

            // balanceOf[from] -= amount;
            // balanceOf[to] += amount;
            _transfer(from, to, amount);
            allowance[from][msg.sender] -= amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function burnTokens(address _owner, uint256 amount) public /*onlyOwner*/ returns(bool) {
        _burn(_owner, amount);
        return true;
    }

    // modifier onlyOwner() {
    //     if (msg.sender != owner || !isMinter[msg.sender]) {
    //         revert ERC20__NotOwner();
    //     }
    //     _;
    // }
}