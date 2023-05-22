// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlokiMarketPlace {
  uint public offerCount;
  uint public ListngPrice=0.02 ether;
  mapping (uint => _Offer) public offers;
  mapping (address => uint) public userFunds;
  address admin;
  
  
  struct _Offer {
    uint offerId;
    uint id;
    address user;
    uint price;
    bool fulfilled;
    bool cancelled;
  }

  event Offer(
    uint offerId,
    uint id,
    address user,
    uint price,
    bool fulfilled,
    bool cancelled,
    address contract_address
  );

  event OfferFilled(uint offerId, uint id, address newOwner);
  event OfferCancelled(uint offerId, uint id, address owner);
  event ClaimFunds(address user, uint amount);

  constructor() {
     admin=msg.sender;
  }
  
  function makeOffer(uint _id, uint _price,address nft_contract_address) public payable {
     require(msg.value>=ListngPrice,"0.02 Ethers is needed to Create a Market Item");
    ERC721 nft_contract = ERC721(nft_contract_address);
    nft_contract.transferFrom(msg.sender, address(this), _id);
    offerCount ++;
    offers[offerCount] = _Offer(offerCount, _id, msg.sender, _price, false, false);
    emit Offer(offerCount, _id, msg.sender, _price, false, false,nft_contract_address);
  }

  function fillOffer(uint _offerId,address nft_contract_address) public payable {
   ERC721 nft_contract = ERC721(nft_contract_address);
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user != msg.sender, 'The owner of the offer cannot fill it');
    require(!_offer.fulfilled, 'An offer cannot be fulfilled twice');
    require(!_offer.cancelled, 'A cancelled offer cannot be fulfilled');
    require(msg.value == _offer.price, 'The ETH amount should match with the NFT Price');
    nft_contract.transferFrom(address(this), msg.sender, _offer.id);
    _offer.fulfilled = true;
    userFunds[_offer.user] += msg.value;
    emit OfferFilled(_offerId, _offer.id, msg.sender);
  }

  function cancelOffer(uint _offerId,address nft_contract_address) public {
     ERC721 nft_contract = ERC721(nft_contract_address);
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'A fulfilled offer cannot be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    nft_contract.transferFrom(address(this), msg.sender, _offer.id);
    _offer.cancelled = true;
    emit OfferCancelled(_offerId, _offer.id, msg.sender);
  }

  function claimFunds() public {
    require(userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
    payable(msg.sender).transfer(userFunds[msg.sender]);
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }
  function getUserAuctions(address user_address)public view  returns(_Offer[]memory) {
      uint256 AuctionCount=0;
      uint currentIndex = 0;
      //get user address
      //loop through items mapping
      for(uint256 i=0;i<=offerCount;i++){
        if(offers[i+1].user==user_address){
            AuctionCount++;
        }
        
      }
        _Offer[] memory itemsarray= new _Offer[](AuctionCount);
          for (uint i = 0; i <=offerCount; i++) {
        if(offers[i+1].user==user_address) {
          uint currentId = i + 1;
          _Offer storage currentItem = offers[currentId];
          itemsarray[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      //save user data in an array
      //return the array
      return itemsarray;
  }
  function Withdraw() public payable {
     require(msg.sender==admin,"only Owner can Call this Function");
      payable(msg.sender).transfer(msg.value);
  }
  function TransferOwnership(address _new_owner)public {
        require(msg.sender==admin,"only owner can call this function");
        admin=_new_owner;
  }


  // Fallback: reverts if Ether is sent to this smart-contract by mistake
  fallback () external {
    revert();
  }
}