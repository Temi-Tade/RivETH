// SPDX-License-Identifier: MIT

pragma solidity 0.8.36;

import {ERC20} from "./ERC20.sol"; // mock ERC20 token

/// @title AppStore contract
/// @author Temiloluwa Akintade
/// @notice A smart contract that manages a decentralized web app store, where devs can list their web apps and users can find them

contract AppStore {
    // 1. register dev
        // dev lists web app (URL, no `http://` prefix, category, upvotes, downvotes)
        // charge lisiting fee ✅
        // no duplicate listing (avoid same URL, for security reasons) ✅
        // avoid empty strings ✅
        // only dev can edit listing/ delist app ✅
        // devs can transfer ownership to another address, the new address becomes the owner of the key/id ✅
        // buy tokens (ERC20), that will be used for listing ✅
        // NFTs (first app, 5th...; 25 users, 50...) for milestones
    // 2. unique key/id is (bytes32) assigned to the URL string and stored ✅
    // 3. the unique key can be resolved to the URL string ✅
    // 4. frontend handles display
        // use fetch API to url to confirm if it truly exists
        // warn users to always verify devs and app IDs
    // 5. handle ratings ✅
        // upvote and downvote
        // avoid duplicate votes

    // errors //
    error AppStore__PaymentRequired();
    error AppStore__ListingAlreadyExists();
    error AppStore__InvalidAction();
    error AppStore__UrlExists();
    error AppStore__EmptyString();

    // state variables //
    uint256 private constant REGISTRATION_FEE = 0.001 ether;
    uint256 private constant LISTING_FEE = 5 ether; // use chainlink/ cutom ERC20 token & listing fee should be 1 USDT ??
    uint256 private constant EDIT_FEE = 2 ether;
    address private s_owner;
    ERC20 private s_tokenAddress;
    struct App {
        string name;
        string url; // unique, same URLs cannot be listed
        string category;
        address owner;
        uint256 lastModified;
        uint256 upvotes;
        uint256 downvotes;
    }
    mapping(bytes32 appKey => App app) private s_apps;
    mapping(address dev => bool isRegistered) private s_devs;
    mapping(address user => mapping(bytes32 appKey => uint8 voteId)) private s_votes;

    // events //
    event RegisterDev(address indexed dev);
    event BuyTokens(address indexed dev, uint256 amount);
    event ListApp(address indexed owner, App app);
    event EditApp(address owner, bytes32 appkey);
    event DelistApp(address owner);
    event TransferOwnership(bytes32 appKey, address oldOwner, address newOwner);
    event RateApp(bytes32 appKey, address user);
    event SponsorApp(address sponsor);

    constructor(ERC20 _tokenAddress) {
        s_owner = msg.sender;
        s_tokenAddress = _tokenAddress;
        ERC20(_tokenAddress).whiteListMinter(address(this)); // white list app store contract as minter of ERC20 token, this is for development, use chainlink in prod
    }

    modifier appGuard(bytes32 _appKey) {
        _performChecks(_appKey);
        _;
    }

    modifier nonEmptyString(string memory _appUrl) {
        // handle empty strings
        _emptyStringCheck(_appUrl);
        _;
    }

    function _performChecks(bytes32 _appKey) internal view {
        address appOwner = s_apps[_appKey].owner;

        // does app exist? || is owner?
        if (appOwner == address(0) || msg.sender != appOwner) {
            revert AppStore__InvalidAction();
        }
    }

    function _emptyStringCheck(string memory _appString) internal pure {
        // revert on empty strings
        if (bytes(_appString).length == 0) {
            revert AppStore__EmptyString();
        }
    }

    function _createAppKey(string memory _appUrl) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encode(_appUrl)));
    }

    // public functions //
    /// @notice Buy ERC20 tokens to be used for dev activities
    /// @param _amount Amount to buy, min 5, max 100
    function buyTokens(uint256 _amount) public payable {
        if (_amount == 0 || _amount < 5 || _amount > 100) {
            revert AppStore__InvalidAction();
        }
        // 10 AST ($2 => 0.001 eth) = ((1e15 * 10)/10)*2000
        if (msg.value != (REGISTRATION_FEE*_amount)/10) {
            revert AppStore__PaymentRequired();
        }

        emit BuyTokens(msg.sender, _amount);
        ERC20(s_tokenAddress).mintTokens(msg.sender, _amount*10**18);
    }

    /// @notice Register as a dev to list apps
    function registerDev() public payable {
        if (msg.value != REGISTRATION_FEE) {
            revert AppStore__PaymentRequired();
        }
        s_devs[msg.sender] = true;

        emit RegisterDev(msg.sender);
        ERC20(s_tokenAddress).mintTokens(msg.sender, 15e18);
    }

    /// @notice List an App
    /// @param _name App name
    /// @param _url App URL, URLs cannot be re-listed
    /// @param _category App category
    function listApp(string memory _name, string memory _url, string memory _category) public nonEmptyString(_name) nonEmptyString(_url) nonEmptyString(_category) returns(bool) {
        // must be a developer to list an app
        if (!s_devs[msg.sender]) {
            revert AppStore__InvalidAction();
        }
        // listing fee
        uint256 devTokenBalance = ERC20(s_tokenAddress).balanceOf(msg.sender);
        if (devTokenBalance < LISTING_FEE) {
            revert AppStore__PaymentRequired();
        }

        bool success = ERC20(s_tokenAddress).burnTokens(msg.sender, LISTING_FEE);
        require(success, "An error occured while listing");
        
        App memory newApp = App({
            name: _name,
            url: _url,
            category: _category,
            owner: msg.sender,
            lastModified: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });
        bytes32 _appKey = _createAppKey(newApp.url);

        // check if a url already exists
        if (s_apps[_appKey].owner != address(0)) {
            revert AppStore__ListingAlreadyExists(); // should other details be in the revert message??
        }

        s_apps[_appKey] = newApp;
        emit ListApp(msg.sender, newApp);

        return success;
    }

    /// @notice Modify app details
    /// @dev Only app owner can edit details, cooldown of 30 days is required
    /// @dev Maps old app details to a new app key, other app details remain the same
    /// @param _appKey ID of the app to edit
    /// @param _newName New name of the app
    /// @param _newUrl New url to point to, cannot be same as current url or a url that already exists in the store
    function editAppDetails(bytes32 _appKey, string memory _newName, string memory _newUrl) public appGuard(_appKey) nonEmptyString(_newUrl) nonEmptyString(_newName) returns(bool) {
        string memory appUrl = s_apps[_appKey].url;

        // checks
        // payment
        uint256 devTokenBalance = ERC20(s_tokenAddress).balanceOf(msg.sender);
        if (devTokenBalance < LISTING_FEE) {
            revert AppStore__PaymentRequired();
        }
        // cannot use same url
        if (keccak256(abi.encodePacked(appUrl)) == keccak256(abi.encodePacked(_newUrl))) {
            revert AppStore__UrlExists();
        }
        // has cooldown passed
        uint256 passedTime = block.timestamp - s_apps[_appKey].lastModified;
        if (passedTime < 30 seconds /*days*/) {
            revert AppStore__InvalidAction();
        }

        bytes32 newAppKey = _createAppKey(_newUrl);
        if (s_apps[newAppKey].owner != address(0)) {
            revert AppStore__InvalidAction();
        }

        App memory oldApp = s_apps[_appKey];
        oldApp.name = _newName;
        oldApp.url = _newUrl;
        oldApp.lastModified = block.timestamp;
        // update id, this is more like 'porting' the old app details
        s_apps[newAppKey] = oldApp;

        delete s_apps[_appKey]; // delete current id
        emit EditApp(msg.sender, newAppKey);

        bool success = ERC20(s_tokenAddress).burnTokens(msg.sender, LISTING_FEE);
        return success;
    }

    /// @notice Delist an app
    /// @param _appKey ID of the app to delist
    function delistApp(bytes32 _appKey) public appGuard(_appKey) returns(bool) {
        // checks
        // payment
        uint256 devTokenBalance = ERC20(s_tokenAddress).balanceOf(msg.sender);
        if (devTokenBalance < EDIT_FEE) {
            revert AppStore__PaymentRequired();
        }

        delete s_apps[_appKey];
        emit DelistApp(msg.sender);

        bool success = ERC20(s_tokenAddress).burnTokens(msg.sender, EDIT_FEE);
        return success;
    }

    /// @notice Transfer ownership of a listing
    /// @dev Only app owner can transfer app, receiver must be a registered dev
    /// @param _appKey ID of app to transfer
    /// @param _newOwner Address of receiver
    function transferAppOwnership(bytes32 _appKey, address _newOwner) public appGuard(_appKey) returns(bool) {
        address appOwner = s_apps[_appKey].owner;

        // checks
        // payment
        uint256 devTokenBalance = ERC20(s_tokenAddress).balanceOf(msg.sender);
        if (devTokenBalance < EDIT_FEE) {
            revert AppStore__PaymentRequired();
        }
        // can only transfer app ownership to a dev
        if (!s_devs[_newOwner]) {
            revert AppStore__InvalidAction();
        }

        s_apps[_appKey].owner = _newOwner;
        emit TransferOwnership(_appKey, appOwner, _newOwner);

        bool success = ERC20(s_tokenAddress).burnTokens(msg.sender, EDIT_FEE);
        return success;
    }

    /// @notice Rate an app
    /// @dev Users can upvote or downvote, cannot give the same rating twice
    /// @param _appKey ID of app to rate
    /// @param _vote Vote ID, 1 for downvote, 2 for upvote
    function rateApp(bytes32 _appKey, uint8 _vote) public {
        // 1 -> downvote; 2 -> upvote
        if (s_votes[msg.sender][_appKey] == _vote || _vote > 2 || _vote == 0) {
            revert AppStore__InvalidAction(); // cannot give same vote/invalid vote
        } else {
            if (s_votes[msg.sender][_appKey] == 1) { // if msg.sender has downvoted before
                // upvote
                s_apps[_appKey].upvotes += 1; // update upvotes
                if (s_apps[_appKey].downvotes > 0) s_apps[_appKey].downvotes -= 1; // and update downvotes
            } else if (s_votes[msg.sender][_appKey] == 2) {
                // downvote
                s_apps[_appKey].downvotes += 1; // update downvotes
                if (s_apps[_appKey].upvotes > 0) s_apps[_appKey].upvotes -= 1; // update upvotes
            } else { // msg.sender has not rated, normal flow
                if (_vote == 1) {
                    s_apps[_appKey].downvotes += 1;
                } else {
                    s_apps[_appKey].upvotes += 1;
                }
            }
            s_votes[msg.sender][_appKey] = _vote;
        }

        emit RateApp(_appKey, msg.sender);
    }

    function sponsorApp(bytes32 _appKey) public payable {
        address appOwner = s_apps[_appKey].owner;

        if (appOwner == address(0)) {
            revert AppStore__InvalidAction();
        }
    
        if (msg.value == 0) {
            revert AppStore__PaymentRequired();
        }

        emit SponsorApp(msg.sender);

        (bool success, ) = appOwner.call{value: msg.value}("");
        require(success, "An error occured");
    }

    // getters //
    function getOwner() external view returns(address) {
        return s_owner;
    }

    function getAppDetails(bytes32 _appKey) external view returns(App memory) {
        return s_apps[_appKey];
    }

    function getAppKey(string memory _url) external pure returns(bytes32) {
        return bytes32(_createAppKey(_url));
    }

    function getUserRating(address user, bytes32 _appKey) external view returns(uint8) {
        return s_votes[user][_appKey];
    }
}