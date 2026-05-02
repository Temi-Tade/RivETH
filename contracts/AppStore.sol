// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract AppStore {
    // 1. register dev
        // dev lists web app (URL, no `http://` prefix, category, upvotes, downvotes)
        // charge lisiting fee ✅
        // no duplicate listing (avoid same URL, for security reasons) ✅
        // avoid empty strings
        // only dev can edit listing/ delist app ✅
        // devs can transfer ownership to another address, the new address becomes the owner of the key/id ✅
        // buy tokens (ERC20), that will be used for listing ??
        // NFTs (first app, 5th...; 25 users, 50...) for milestones
    // 2. unique key/id is (bytes32) assigned to the URL string and stored ✅
    // 3. the unique key can be resolved to the URL string ✅
    // 4. frontend handles display
        // use fetach request to url to confirm if it truly exists
        // warnusers to always verify devs and app IDs
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
    uint256 private constant LISTING_FEE = 0.001 ether; // use chainlink/ cutom ERC20 token & listing fee should be 1 USDT ??
    uint256 private constant EDIT_FEE = 0.0005 ether;
    address private s_owner;
    struct App {
        string name;
        string url; // unique, same URLs cannot be listed
        string category;
        address owner;
        uint256 upvotes;
        uint256 downvotes;
    }
    mapping(bytes32 appKey => App app) private s_apps;
    mapping(address user => mapping(bytes32 appKey => uint8 voteId)) private s_votes;

    // events //
    event ListApp(address indexed owner, App app);
    event EditApp(address owner, bytes32 appkey);
    event DelistApp(address owner);
    event TransferOwnership(bytes32 appKey, address oldOwner, address newOwner);
    event RateApp(bytes32 appKey, address user);
    event SponsorApp(address sponsor);

    constructor() {
        s_owner = msg.sender;
    }

    modifier appGuard(bytes32 _appKey) {
        _performChecks(_appKey);
        _;
    }

    function _performChecks(bytes32 _appKey) internal view {
        address appOwner = s_apps[_appKey].owner;

        // does app exist? || is owner?
        if (appOwner == address(0) || msg.sender != appOwner) {
            revert AppStore__InvalidAction();
        }
    }

    function _createAppKey(string memory _appUrl) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encode(_appUrl)));
    }

    // public functions //

    /// @notice List an App
    /// @param _name App name
    /// @param _url App URL, URLs cannot be re-listed
    /// @param _category App category
    function listApp(string memory _name, string memory _url, string memory _category) public payable {
        // revert on empty strings
        if (bytes(_name).length == 0 || bytes(_url).length == 0) {
            revert AppStore__EmptyString();
        }
        // listing fee
        if (msg.value != LISTING_FEE) {
            revert AppStore__PaymentRequired();
        }

        App memory newApp = App({
            name: _name,
            url: _url,
            category: _category,
            owner: msg.sender,
            upvotes: 0,
            downvotes: 0
        });
        bytes32 _appKey = _createAppKey(newApp.url);

        // check if an owner already exists
        // chances are very slim
        // for this revert to occur, the same name, category, url
        // owner of the app to be listed already exists
        if (s_apps[_appKey].owner != address(0)) {
            revert AppStore__ListingAlreadyExists(); // should other details be in the revert message??
        }

        s_apps[_appKey] = newApp;
        emit ListApp(msg.sender, newApp);
    }

    function editAppUrl(bytes32 _appKey, string memory _newUrl) public payable appGuard(_appKey) {
        string memory appUrl = s_apps[_appKey].url;

        // checks
        // payment
        if (msg.value != EDIT_FEE) {
            revert AppStore__PaymentRequired();
        }
        // handle empty strings
        if (bytes(_newUrl).length == 0) {
            revert AppStore__EmptyString();
        }
        // cannot use same url
        if (keccak256(abi.encodePacked(appUrl)) == keccak256(abi.encodePacked(_newUrl))) {
            revert AppStore__UrlExists();
        }

        bytes32 newAppKey = _createAppKey(_newUrl);
        if (s_apps[newAppKey].owner != address(0)) {
            revert AppStore__InvalidAction();
        }

        App memory oldApp = s_apps[_appKey];
        // update id, this is more like 'porting' the old app details
        s_apps[newAppKey] = App({
            name: oldApp.name,
            url: _newUrl,
            category: oldApp.category,
            owner: msg.sender,
            upvotes: oldApp.upvotes,
            downvotes: oldApp.downvotes
        });
        delete s_apps[_appKey]; // delete current id
        emit EditApp(msg.sender, newAppKey);
    }

    function delistApp(bytes32 _appKey) public payable appGuard(_appKey) {
        // checks
        // payment
        if (msg.value != EDIT_FEE) {
            revert AppStore__PaymentRequired();
        }

        delete s_apps[_appKey];
        emit DelistApp(msg.sender);
    }

    function transferAppOwnership(bytes32 _appKey, address _newOwner) public payable appGuard(_appKey) {
        address appOwner = s_apps[_appKey].owner;

        // checks
        // payment
        if (msg.value != EDIT_FEE) {
            revert AppStore__PaymentRequired();
        }

        s_apps[_appKey].owner = _newOwner;
        emit TransferOwnership(_appKey, appOwner, _newOwner);
    }

    function rateApp(bytes32 _appKey, uint8 vote) public {
        // 1 -> downvote; 2 -> upvote
        if (s_votes[msg.sender][_appKey] == vote || vote > 2 || vote == 0) {
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
                if (vote == 1) {
                    s_apps[_appKey].downvotes += 1;
                } else {
                    s_apps[_appKey].upvotes += 1;
                }
            }
            s_votes[msg.sender][_appKey] = vote;
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