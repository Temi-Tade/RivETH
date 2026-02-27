// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract Example {
    uint256 public mtk = 10e5; // x
    uint256 public usdc = 1000e4; // y
    uint256 immutable constant_product = mtk * usdc;
    uint8 constant swap_fee = 3; // 0.3% => 997/1000
    uint256 public usdcToReceive;

    function swapmtkForUsdc(uint256 _amount) public {
        uint256 old_usdc = usdc;
        mtk += _amount;

        uint256 new_usdc_reserve = constant_product / mtk;
        usdc = new_usdc_reserve;

        usdcToReceive = old_usdc - new_usdc_reserve;
    }

    function swapUsdcFormtk(uint256 _amount) public {
        
    }

    function getMtkUsdcPrice() external view returns(uint256) {
        return usdc/mtk;
    }
} 