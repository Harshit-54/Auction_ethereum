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

    mapping(address => uint) public pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

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
    
    function encode(string str) public pure returns (bytes4){
        return bytes4(keccak256(abi.encodePacked(str)));
    }

    function checkEncodedBid(string memory _str) public view returns(bool){
        if(keccak256(bytes(bids[msg.sender].blindedBid))==keccak256(bytes(_str)))return true;
        return false;
    }
    
    function bid(string _blindedBid) public payable onlyBefore(biddingEnd){
        bids[msg.sender]=Bid({
            blindedBid: _blindedBid,
            deposited: msg.value
        });
    }

    
    function reveal(uint _value) public payable   
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd) 
        {
        uint refund;
        Bid storage bidToCheck = bids[msg.sender];
        refund = bidToCheck.deposited;
         if(bidToCheck.deposited >= _value*1000000000000000000){
            if(placeBid(msg.sender,_value)){
                refund-=_value*1000000000000000000;
            }
        }
        bidToCheck.blindedBid = "";
        bidToCheck.deposited= 0;
        msg.sender.transfer(refund);
    }

    function withdraw() public payable{
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    function auctionEnd() public payable 
    onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal returns (bool success)
    {
        if (value*1000000000000000000 <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value*1000000000000000000;
        highestBidder = bidder;
        return true;
    }
}