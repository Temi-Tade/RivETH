// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title A minimalistic Auctioning Smart Contract
/// @author Temiloluwa Akintade
/// @notice Bidders send ETH to the contract, there is a minimum bid which increases
// as new, higher bids are placed. Multiple bids are allowed from
// the highest bidder is automatically chosen by the contract
// the bidders who do not bid the highest are refunded their bids.
/// @dev A minimumBid is set at deployment time,
// this minimumBid is updated anytime there is a new, improved bid.
//A mapping is used to keep track of bidders and the bids they place.

// in a real-world usecase, an RWA/NFT could be tokenized and passed as an arg
// to startAucton() and the minimumBid is also passed as an arg to the startAuction()
// function. The highest bidder is sent/minted the RWA/NFT at the end of the auction.

contract Auction {
    // bidders enter by sending their bids (ETH) -
    // there should be a minimum bid to enter -
    // number of bids placed, highest bidder and bids placed can be seen -
    // highest bidder wins

    constructor (uint256 _minimumBid) {
        i_owner = msg.sender;
        minimumBid = _minimumBid; // in wei
    }

    // errors
    error Auction__NotOwnerError();
    error Auction__RefundError(string);
    error Auction__WithdrawError(string);
    error Auction__BelowMinBidError(string);
    error Auction__BelowMinWithdrawError(string);

    // events
    event PlaceBid(address indexed bidder, uint256 amount);
    event RefundBidder(address indexed bidder, uint256 amount);

    // private variables
    address private immutable i_owner;
    bool canBid;
    uint256 private minimumBid;
    uint256 private numberOfBids;
    uint256 private numberOfBidders;
    address[] private listOfBidders;
    mapping(address bidder => uint256[] bids) private bids;

    modifier onlyOwner {
        if (msg.sender != i_owner) {
            revert Auction__NotOwnerError();
        }
        _;
    }

    fallback() external payable {
        placeBid();
    }

    receive() external payable {
        placeBid();
    }

    function startAuction() external onlyOwner {
        canBid = true;
    }

    function endAuction() external onlyOwner {
        // stop bidding and refund all ETH for bidders who could not bid the highest,
        // for the highest bidder, hold his bid and refund all previous bids, if any.

        canBid = false;
        address currentBidder;
        
        for (uint256 index = 0; index < listOfBidders.length; index++) {
            currentBidder = listOfBidders[index];
            uint256 totalBidPlacedByCurrentBidder;

            for (uint256 bidIndex = 0; bidIndex < bids[currentBidder].length; bidIndex++) {
                // calculate the amount to refund to each bidder, safe minimumBid (the highestBid)
                if(bids[currentBidder][bidIndex] != minimumBid) {
                    totalBidPlacedByCurrentBidder += bids[currentBidder][bidIndex];
                }
            }

            bids[currentBidder] = new uint256[](0);
            refund(payable(currentBidder), totalBidPlacedByCurrentBidder);
            emit RefundBidder(currentBidder, totalBidPlacedByCurrentBidder);
        }

        minimumBid = 0;
        numberOfBids = 0;
        numberOfBidders = 0;
        listOfBidders = new address[](0);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        // only the deployer can withdraw funds, the minimum withdrawal amount
        // is 10% of the contract balance at the time of withdrawal.
        require(!canBid, "Cannot withdraw while bidding is still on");
        uint256 minimumWithdrawal;
        minimumWithdrawal = (address(this).balance * 10) / 100;

        if (_amount < minimumWithdrawal) {
            revert Auction__BelowMinWithdrawError("Amount not up to mimnimum withdrawal");
        }

        (bool ok, ) = msg.sender.call{value: _amount}("");
        if(!ok) revert Auction__WithdrawError("Withdraw failed");
    }

    function refund(address payable to, uint256 amount) internal {
        (bool ok, ) = to.call{value: amount}("");

        if (!ok) revert Auction__RefundError("Refund failed");
    }

    // should this return true??
    function placeBid() public payable {
        // bids can only be placed when canBid == true; a bid should be higher than the minimum bid
        // the initial minimumBid is hardcoded in the constructor and any new bids should be > it
        // the new bid that is > the current minimumBid becomes the new minimumBid.
        if ((canBid == false) || (msg.value <= minimumBid)) {
            revert Auction__BelowMinBidError("Below minimum bid");
        }

        minimumBid = msg.value;
        numberOfBids += 1;
        if (bids[msg.sender].length == 0) {
            listOfBidders.push(msg.sender);
        }
        bids[msg.sender].push(msg.value);
        emit PlaceBid(msg.sender, msg.value);
    }

    // getter functions
    function getHighestBid() external view returns(address bidder, uint256 bid) {
        address highestBidder;

        if (listOfBidders.length == 1) {
            highestBidder = listOfBidders[0];
        } else {
            for (uint256 index = 0; index < listOfBidders.length; index++) {
                uint256 totalBidsByBidder = bids[listOfBidders[index]].length;

                for (uint256 bidIndex = 0; bidIndex < totalBidsByBidder; bidIndex++) {
                    if (bids[listOfBidders[index]][bidIndex] == minimumBid) {
                        highestBidder = listOfBidders[index];
                    }
                }
            }
        }

        return (highestBidder, minimumBid);
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getMinimumBid() external view returns(uint256) {
        return minimumBid;
    }

    function getBidsPlaced(address _bidder) external view returns(uint256[] memory) {
        return bids[_bidder];
    }

    function getNumberOfBids() external view returns(uint256) {
        return numberOfBids;
    }

    function getNumberOfBidders() external view returns(uint256) {
        return listOfBidders.length;
    }
}