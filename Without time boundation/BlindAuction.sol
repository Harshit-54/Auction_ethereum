pragma solidity ^0.4.0;
contract BlindAuction {
    struct Bid {
        string blindedBid;
        uint deposited;
    }
  
    address public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid) public bids;

    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) public pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    /// Modifiers are a convenient way to validate inputs to
    /// functions. `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }

    constructor(
        uint _biddingTime,
        uint _revealTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }
    
    function gettime () public view returns(uint){
        return block.timestamp;
    }
    function bid()
        public
        payable
        // onlyBefore(biddingEnd)
    {
        bids[msg.sender]=Bid({
            blindedBid: "temporarystring",
            deposited: msg.value
        });
    }
    
  

    /// Reveal your blinded bids. You will get a refund for all
    /// correctly blinded invalid bids and for all bids except for
    /// the totally highest.
    function reveal(
        uint _value,
        bool _fake
    )
        public
        payable
        // onlyAfter(biddingEnd)
        // onlyBefore(revealEnd)
    {
       
        uint refund;
        Bid storage bidToCheck = bids[msg.sender];
        refund = bidToCheck.deposited;
      
        if(!_fake && bidToCheck.deposited >= _value*1000000000000000000){
            if(placeBid(msg.sender,_value)){
                refund-=_value*1000000000000000000;
            }
        }
        // Make it impossible for the sender to re-claim
        // the same deposit.
        bidToCheck.blindedBid = "";
        bidToCheck.deposited= 0;
    
        msg.sender.transfer(refund);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public payable{
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `transfer` returns (see the remark above about
            // conditions -> effects -> interaction).
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd()
        public
        payable
        // onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value*1000000000000000000 <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value*1000000000000000000;
        highestBidder = bidder;
        return true;
    }
}