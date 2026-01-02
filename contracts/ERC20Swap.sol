// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "./ERC20.sol";
import {IERC1363Receiver} from "../interfaces/IERC1363Receiver.sol";

contract ERC20Swap {
    // deploy ERC20 (assume ERC20 to be USDT)
    // deploy Swap and call mint(to, 20000) from ERC20 contract
    // Swap will serve as a liquidity pool (ETH/USDT)
    // x * y = k (constant product rule)
    // |   \
    // ETH USDT
    // initially, 1 ETH = 2000 USDT
    // initial price, ETH/USDT = 2000 USDT
    // 10 ETH * 20_000 USDT = 200_000
    // constant product = 200_000
    // x` * y` = k (after swap)
    // if user sends ETH to get UDST,
    // new ETH reserve, x` = 11
    // new USDT reserve, y` = k/x` = 200_000/11 = 18_181.82
    // user receives y - y` = 20_000 - 18_181.82 = 1_818.18 USDT
    // new ETH/USDT price is k/x` = 18_181.82/11 =  1_652.89 USDT

    // to add: use Enums when pool is locked
    // pool should be locked when any token
    // goes below a min amount.

    // pool is also locked after deployment if the
    // starting usdt_reserve has not been reached

    error ERC20Swap__DeployWithMoreETH();
    error ERC20Swap__DepositMoreETH();
    error ERC20Swap__NotEnoughUSDT();

    event Deposit(address indexed depositor, address indexed owner, uint256 amount);
    event Swap(address indexed _from, address indexed _to, uint256 _in, uint256 _out);

    constructor(/*string memory _name,*/ ERC20 _usdtContractAddress) payable {
        // name = _name;

        if (msg.value < 10 ether) {
            revert ERC20Swap__DeployWithMoreETH();
        }

        eth_reserve = msg.value;
        i_usdt = ERC20(_usdtContractAddress);
    }

    ERC20 private immutable i_usdt;
    // string internal name;
    uint256 public constant ETH_DECIMALS = 18;
    uint256 public constant USDT_DECIMALS = 6;

    uint256 internal eth_reserve;
    uint256 internal usdt_reserve;
    uint256 internal eth_usdt_price = 2_000; // in a real-world scenario, this will be gotten with chainlink

    uint256 internal constant CONSTANT_PRODUCT = 10 * 20_000; // starting_eth_reserve * starting_usdt_reserve
    uint256 internal constant MINIMUM_ETH_DEPOSIT = 0.001 ether;
    uint256 internal constant MINIMUM_USDT_DEPOSIT = 1000000;

    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns(bytes4) {
        // check if caller is ERC20
        require(msg.sender == address(i_usdt), "Caller not ERC20 token");

        if (data.length == 0) {
            // add value to reserve
            usdt_reserve += value;
        } else {
            (, bytes memory _data) = abi.decode(data, (address, bytes));

            if (bytes4(_data) == 0xb3f6145f) {
                (bool ok, ) = address(this).call(abi.encodeWithSelector(0xb3f6145f, value));
                require(ok, "low-level swap call failed");
            }
        }

        emit Deposit(operator, from, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function swapEthForUsdt() external payable {
        if(msg.value < MINIMUM_ETH_DEPOSIT) {
            revert ERC20Swap__DepositMoreETH();
        }
        eth_reserve += msg.value;
        
        uint256 initial_usdt_reserve = usdt_reserve;
        uint256 new_usdt_reserve = (CONSTANT_PRODUCT * 10**ETH_DECIMALS) / eth_reserve;
        usdt_reserve = new_usdt_reserve;

        uint256 usdtToReceive = initial_usdt_reserve - usdt_reserve;

        emit Swap(msg.sender, msg.sender, msg.value, usdtToReceive);

        bool success = i_usdt.transfer(msg.sender, usdtToReceive);
        require(success, "Swap failed");
    }

    function swapUsdtForEth(uint256 _usdtAmount) external {
        if (_usdtAmount* 10**USDT_DECIMALS < MINIMUM_USDT_DEPOSIT) {
            revert ERC20Swap__NotEnoughUSDT();
        }

        usdt_reserve += _usdtAmount;

        // update this there is no need to use safeTransferFrom to 'pull'
        // USDT. The user sends USDT and the contract receives it and
        // calculates ETH to swap it for
        bool transferSuccess = i_usdt.transferFrom(msg.sender, address(this), _usdtAmount);
        require(transferSuccess, "USDT Transfer error.");

        uint256 initial_eth_reserve = eth_reserve;
        uint256 new_eth_reserve = (CONSTANT_PRODUCT) / usdt_reserve;
        eth_reserve = new_eth_reserve *10**ETH_DECIMALS;

        uint256 ethToReceive = initial_eth_reserve - eth_reserve;
        (bool ok, ) = msg.sender.call{value: ethToReceive}("");
        require(ok, "ETH transfer error");
    }

    // <-------- getter functions -------------> //
    function getEthUsdtReserves() external view returns(uint256, uint256) {
        return (eth_reserve, usdt_reserve * 10**USDT_DECIMALS);
    }

    function getEthUsdtPrice() external view returns(uint256) {
        return ((usdt_reserve *10**ETH_DECIMALS)/eth_reserve) *10**USDT_DECIMALS;
    }
}