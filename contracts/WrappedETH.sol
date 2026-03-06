// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {ERC20} from "./ERC20.sol";

/// @title Wrapped Ether - An ERC20 representation of ETH
/// @author Temiloluwa Akintade
/// @notice This contract mints WETH for every ETH deposited as collateral on a 1:1 basis

contract WrappedETH is ERC20 {
    error WrappedETH__NotEnoughWETHToBurn();
    error WrappedETH__WithdrawFailed();
    error WrappedETH__ZeroError();

    event DepositETH(address indexed depositor, uint256 amount);
    event WithdrawETH(address indexed owner, uint256 amount);

    constructor() ERC20("Wrapped ETH", "WETH") {}

    function _burn(uint256 _amount) internal {
        if (_amount == 0) {
            revert WrappedETH__ZeroError();
        }
        if (balanceOf[msg.sender] < _amount) {
            revert WrappedETH__NotEnoughWETHToBurn();
        }

        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;

        emit WithdrawETH(msg.sender, _amount);
    }

    function deposit() public payable {
        uint256 _ethToDeposit = msg.value;
        if (_ethToDeposit == 0) {
            revert WrappedETH__ZeroError();
        }

        _mint(msg.sender, _ethToDeposit);

        emit DepositETH(msg.sender, _ethToDeposit);
    }

    function withdraw(uint256 _amount) public {
        _burn(_amount);
        (bool ok, ) = msg.sender.call{value: _amount}("");

        if (!ok) {
            revert WrappedETH__WithdrawFailed();
        }
    }
}