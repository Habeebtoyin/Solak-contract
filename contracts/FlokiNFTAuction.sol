// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";



contract FlokiNFTAuction is IERC721Receiver {
        address public owner;
        uint256 public  AUCTION_PRICE=0.02 ether;
    constructor(){
            owner=msg.sender;
    }
    struct tokenDetails {
        address seller;
        uint256 id;
        uint128 price;
        uint256 duration;
        uint256 maxBid;
        address maxBidUser;
        bool isActive;
        uint256[] bidAmounts;
        address[] users;
    }
    uint256 public AuctionCounter;
    mapping(address => mapping(uint256 => tokenDetails)) public tokenToAuction;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public bids;
    
    /**
       Seller puts the item on auction
    */
    function createTokenAuction(
        address _nft,
        uint256 _tokenId,
        uint128 _price,
        uint256 _duration
    ) public  payable {
        require(msg.sender != address(0), "Invalid Address");
        require(_nft != address(0), "Invalid Account");
        require(_price > 0, "Price should be more than 0");
        require(_duration > 0, "Invalid duration value");
        require(msg.value>=AUCTION_PRICE,"0.02 Ethers is needed to Create an Auction");
        tokenDetails memory _auction = tokenDetails({
            seller: msg.sender,
            id: _tokenId,
            price: uint128(_price),
            duration: _duration,
            maxBid: 0,
            maxBidUser: address(0),
            isActive: true,
            bidAmounts: new uint256[](0),
            users: new address[](0)
        });
        AuctionCounter++;
        // address owner = msg.sender;
        ERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
        tokenToAuction[_nft][_tokenId] = _auction;
    }
    /**
       Users bid for a particular nft, the max bid is compared and set if the current bid id highest
    */
    function bid(address _nft, uint256 _tokenId) external payable {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(msg.value >= auction.price, "bid price is less than current price");
        require(auction.isActive, "auction not active");
        require(auction.duration > block.timestamp, "Deadline already passed");
        if (bids[_nft][_tokenId][msg.sender] > 0) {
            (bool success, ) = msg.sender.call{value: bids[_nft][_tokenId][msg.sender]}("");
            require(success);
        }
        bids[_nft][_tokenId][msg.sender] = msg.value;
        if (auction.bidAmounts.length == 0) {
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        } else {
            uint256 lastIndex = auction.bidAmounts.length - 1;
            require(auction.bidAmounts[lastIndex] < msg.value, "Current max bid is higher than your bid");
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        }
        auction.users.push(msg.sender);
        auction.bidAmounts.push(msg.value);
    }
    /**
       Called by the seller when the auction duration is over the hightest bid user get's the nft and other bidders get eth back
    */
    function executeSale(address _nft, uint256 _tokenId) external {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.duration <= block.timestamp, "Deadline did not pass yet");
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        auction.isActive = false;
        if (auction.bidAmounts.length == 0) {
            ERC721(_nft).safeTransferFrom(
                address(this),
                auction.seller,
                _tokenId
            );
        } else {
            (bool success, ) = auction.seller.call{value: auction.maxBid}("");
            require(success);
            for (uint256 i = 0; i < auction.users.length; i++) {
                if (auction.users[i] != auction.maxBidUser) {
                    (success, ) = auction.users[i].call{
                        value: bids[_nft][_tokenId][auction.users[i]]
                    }("");
                    require(success);
                }
            }
            ERC721(_nft).safeTransferFrom(
                address(this),
                auction.maxBidUser,
                _tokenId
            );
        }
    }

    /**
       Called by the seller if they want to cancel the auction for their nft so the bidders get back the locked eeth and the seller get's back the nft
    */
    function cancelAuction(address _nft, uint256 _tokenId) external {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        auction.isActive = false;
        bool success;
        for (uint256 i = 0; i < auction.users.length; i++) {
        (success, ) = auction.users[i].call{value: bids[_nft][_tokenId][auction.users[i]]}("");        
        require(success);
        }
        ERC721(_nft).safeTransferFrom(address(this), auction.seller, _tokenId);
    }

    function getTokenAuctionDetails(address _nft, uint256 _tokenId) public view returns (tokenDetails memory) {
        tokenDetails memory auction = tokenToAuction[_nft][_tokenId];
        return auction;
    }
    function getUserAuctions(address user_address,address nft_contract)public view  returns(tokenDetails[]memory) {
      uint256 AuctionCount=0;
      uint currentIndex = 0;
      //get user address
      //loop through items mapping
      for(uint256 i=0;i<=AuctionCounter;i++){
        if(tokenToAuction[nft_contract][i+1].seller==user_address){
            AuctionCount++;
        }
        
      }
        tokenDetails[] memory itemsarray= new tokenDetails[](AuctionCount);
        for (uint i = 0; i <=AuctionCounter; i++) {
            if(tokenToAuction[nft_contract][i+1].seller==user_address) {
                uint currentId = i + 1;
                tokenDetails storage currentItem = tokenToAuction[nft_contract][currentId];
                itemsarray[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
      //save user data in an array
      //return the array
      return itemsarray;
    }
     function Withdraw() public payable {
     require(msg.sender==owner,"only Owner can Call this Function");
      payable(msg.sender).transfer(msg.value);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    function TransferOwnership(address _new_owner)public{
        require(msg.sender==owner,"only owner can call this function");
        owner=_new_owner;
    }

    receive() external payable {}
}