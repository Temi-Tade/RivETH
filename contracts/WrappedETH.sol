// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

// import {ERC20} from "./ERC20.sol";

/// @title Wrapped Ether - An ERC20 representation of ETH
/// @author Temiloluwa Akintade
/// @notice This contract mints WETH for every ETH deposited as collateral on a 1:1 basis

contract WrappedETH {
    error WrappedETH__NotEnoughWETHToBurn();
    error WrappedETH__WithdrawFailed();
    error WrappedETH__ZeroError();

    // constructor() {}
    uint8 public totalSupply;
    mapping(address owner => uint8 balance) _balanceOf;

    function _mint(address _to, uint8 _amount) internal {
        // if (_amount == 0) {
        //     revert WrappedETH__ZeroError();
        // }
        
        _balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(uint8 _amount) internal {
        if (_amount == 0) {
            revert WrappedETH__ZeroError();
        }
        if (_balanceOf[msg.sender] < _amount) {
            revert WrappedETH__NotEnoughWETHToBurn();
        }

        totalSupply -= _amount;
        _balanceOf[msg.sender] -= _amount;
    }

    function deposit() public payable {
        uint8 _ethToDeposit = getPurchasePrice(uint8(msg.value));
        _mint(msg.sender, _ethToDeposit);
    }

    function withdraw(uint8 _amount) public {
        _burn(_amount);
        (bool ok, ) = msg.sender.call{value: _amount}("");

        if (!ok) {
            revert WrappedETH__WithdrawFailed();
        }
    }

    function getPurchasePrice(uint8 _ethToDeposit) public pure returns(uint8) {
        unchecked {
            return _ethToDeposit;
        }
    }

    function balanceOf(address _owner) external view returns(uint8) {
        return _balanceOf[_owner];
    }
}

// 115792089237316195423570985008687907853269984665640564039457584007913129639936 => 2**256

// function to calculate how much WETH you'll get for ETH deposited
// use the return as the msg.value in depositETH
// pass the big number as msg.value to mint

// use smaller integer bits for ease