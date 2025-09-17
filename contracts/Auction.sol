// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Simple Auction (payable bids + withdraw pattern)
/// @notice Accepts ETH bids, keeps track of highest bidder, supports withdrawals for outbid bidders,
/// and allows the owner to end the auction and claim the highest bid.

contract Auction {
    address public owner;
    uint256 public highestBid;
    address public highestBidder;

    uint256 public auctionEndTime; 
    bool public ended;

    mapping(address => uint256) public pendingReturns;

    event BidPlaced(address indexed bidder, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionCreated(address indexed owner, uint256 endTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        require(!ended, "Auction ended");
        _;
    }

    constructor(uint256 _biddingTimeSeconds) {
        require(_biddingTimeSeconds > 0, "Duration must be > 0");
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTimeSeconds;
        emit AuctionCreated(owner, auctionEndTime);
    }

    function bid() external payable auctionActive {
        require(msg.sender != owner, "Owner cannot bid");
        require(msg.value > highestBid, "Bid not higher than current highest");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) {
            pendingReturns[msg.sender] = amount;
            return false;
        }

        emit Withdrawn(msg.sender, amount);
        return true;
    }

    function endAuction() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction not yet finished");
        require(!ended, "Auction already ended");

        ended = true;

        uint256 winningBid = highestBid;
        address winner = highestBidder;

        highestBid = 0;
        highestBidder = address(0);

        if (winningBid > 0) {
            (bool sent, ) = payable(owner).call{value: winningBid}("");
            require(sent, "Transfer to owner failed");
        }

        emit AuctionEnded(winner, winningBid);
    }

    function timeLeft() external view returns (uint256) {
        if (block.timestamp >= auctionEndTime || ended) return 0;
        return auctionEndTime - block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}
