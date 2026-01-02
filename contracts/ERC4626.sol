// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "./ERC20.sol";

/// @dev throughput this contract, assume assets = shares

contract ERC4626 is ERC20("Matrix USDT", "mUSDT") {
    error ERC4626__AssetTransferError();
    error ERC4626__NotEnoughShares();
    error ERC4626__NotEnoughAllowance();

    /// @param caller tx initiator
    /// @param owner address that received shares
    /// @param assets assets deposited
    /// @param shares shares minted
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares    
    );

    event Withdraw(
        address indexed caller,
        address indexed owner,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    constructor (ERC20 _asset) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(_asset);
        i_underlyingDecimals = success ? assetDecimals : 18;
        i_asset = _asset;
    }

    ERC20 private immutable i_asset;
    uint8 private immutable i_underlyingDecimals;

    function _tryGetAssetDecimals(ERC20 _asset) internal view returns(bool, uint8) {
        return (true, _asset.decimals());
    }

    function _mint(address receiver, uint256 shares) internal override {
        totalSupply += shares;
        balanceOf[receiver] += shares;

        emit Transfer(address(0), receiver, shares);
    }

    function _burn(address owner, uint256 shares) internal {
        if (balanceOf[owner] < shares) {
            revert ERC4626__NotEnoughShares();
        }

        totalSupply -= shares;
        balanceOf[owner] -= shares;
    }

    function _spendAllowance(address owner, address spender, uint256 shares) internal view returns(bool) {
        if (allowance[owner][spender] < shares) {
            revert ERC4626__NotEnoughAllowance();
        }

        return true;
    }

    /// @dev should be view
    function _convertToShares(uint256 assets) internal pure returns(uint256) {
        return assets; // calculation should be done here
    }

    /// @dev should be view
    function _convertToAssets(uint256 shares) internal pure returns(uint256) {
        return shares; // calculation should be done here
    }

    // ---- external functions ---- //
    function asset() external view returns(address) {
        return address(i_asset);
    }

    function totalAssets() external view returns(uint256) {
        return i_asset.balanceOf(address(this));
    }

    /// @dev similar to previous two functions; will also be calculated
    /// @param assets amount of assets to be pulled in
    /// @return shares amount of shares that will be received under ideal 
    /// condtions (no slippage & fees)
    function convertToShares(uint256 assets) external pure returns(uint256) {
        return _convertToShares(assets);
    }

    function convertToAssets(uint256 shares) external pure returns(uint256) {
        return _convertToAssets(shares);
    }

    /// @dev it should be a view function, it calculates shares
    /// the user receives based on assets sent in
    /// @return shares the amount of shares to receive, it is
    /// calculated based on share price and supply
    function previewDeposit(uint256 assets) external pure returns(uint256) {
        return _convertToShares(assets);
    }

    /// @dev same as previewDeposit()
    function previewMint(uint256 shares) external pure returns(uint256) {
        return _convertToAssets(shares);
    }

    /// @dev calculates shares to receive based on assets pulled in
    function deposit(uint256 assets, address receiver) external returns(uint256) {
        bool success = i_asset.transferFrom(msg.sender, address(this), assets);
        
        if (!success) {
            revert ERC4626__AssetTransferError();
        }
        uint256 sharesToReceive = _convertToShares(assets);
        _mint(receiver, sharesToReceive);
        emit Deposit(msg.sender, receiver, assets, sharesToReceive);

        return assets;
    }

    /// @dev calculates assets to pull in based on shares requested
    function mint(uint256 shares, address receiver) external returns(uint256) {
        uint256 assetsToReceive = _convertToAssets(shares);
        bool success = i_asset.transferFrom(msg.sender, address(this), assetsToReceive);

        if (!success) {
            revert ERC4626__AssetTransferError();
        }

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assetsToReceive, shares);

        return shares;
    }

    /// @dev user specifies how many assets to take back
    // and the contract calculates how many corresponding shares to burn
    function withdraw(uint256 assets, address receiver, address _owner) external returns(uint256) {
        if(msg.sender != owner) {
            if(!_spendAllowance(owner, msg.sender, assets)) {
                revert();
            }
            allowance[owner][msg.sender] -= assets;
        }
        uint256 sharesToBurn = _convertToShares(assets);
        _burn(owner, sharesToBurn);
        emit Withdraw(msg.sender, _owner, receiver, assets, sharesToBurn);

        bool success = i_asset.transfer(receiver, assets);
        require(success, "Withdraw error");

        return assets; // what was sent to receiver

    }

    function redeem(uint256 shares, address receiver, address _owner) external returns(uint256) {
        uint256 assetsToSend = _convertToAssets(shares);
        if (msg.sender != owner) {
            if (!_spendAllowance(owner, msg.sender, shares)) {
                revert();
            }
            // update allowance
            allowance[owner][msg.sender] -= assetsToSend;
        }

        _burn(owner, shares);
        emit Withdraw(msg.sender, _owner, receiver, assetsToSend, shares);

        bool success = i_asset.transfer(receiver, assetsToSend);
        require(success, "Redeem error");

        return assetsToSend;
    }

    /// @dev this should be a view function, taking into
    /// account the calculations
    function previewWithdraw(uint256 assets) external pure returns(uint256) {
        return _convertToShares(assets); // how many shares will be burned in ERC4626?
    }

    function previewRedeem(uint256 shares) external pure returns(uint256) {
        return _convertToAssets(shares); // how many ERC20 assets would be transferred?
    }

    /// @dev should be view functions
    /// @dev max amount of assets that can be deposited
    /// and receiver would receive corresponding shares
    /// without hitting valult limits
    function maxDeposit(address receiver) external pure returns(uint256) {
        (receiver);
        return 1; // the value should be dynamic,
        /// each address might have a limit, e.g. new depositors
        /// vs exisiting ones
    }
    /// @dev max amount of shares that can be minted
    /// to a receiver based on assets deposited
    function maxMint(address receiver) external pure returns(uint256) {
        (receiver);
        return 1; //also dynamic;
    }

    function maxWithdraw(address owner) external view returns(uint256) {
        return balanceOf[owner]; // max assets that can be received by `owner` that can be withdrawn
    }

    function maxRedeem(address owner) external view returns(uint256) {
        return balanceOf[owner]; // max shares owned by `owner` that can be burned for assets
    }
}