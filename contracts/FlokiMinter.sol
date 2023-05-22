// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./FlokiCollection.sol";

contract FlokiMinter is ERC721{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  // address public marketplace;
  address owner;
  uint256 mintingSingleNftPrice=0.01 ether;
  uint256 mintingCollectionNftPrice=0.02 ether;
  //mapping(uint=>address)public collectionsList;
  mapping(uint=>Collection)public UserTocollectionsList;
  uint public collectionIds;
  uint public ownerIds;

  event Collection_Created(
    address CollectionOwner,
    address CollectionAddress
  );

  struct  Item {
    uint256 id;
    address creator;
    string uri;//metadata url
  }

  struct Collection{
    uint256 id;
    address creator;
    address collectionAddress;
  }

  

  mapping(uint256 => Item) public Items; //id => Item

  constructor () ERC721("ArtToken", "ARTK") {
    owner=msg.sender;
  }

  function mint(string memory uri) public payable returns (uint256){
    require(msg.value>=mintingSingleNftPrice,"Minimum of 0.01 ether is need to mint");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    // approve(marketplace, newItemId);

    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri
    });

    return newItemId;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  // function setMarketplace(address market) public {
  //   //require(msg.sender ==);
  //   marketplace = market;
  // }
  function CreateCollection(string memory _name,string memory _symbol,string memory collectionImageUri)public payable{
    require(msg.value>=mintingCollectionNftPrice,"It requires the minimum of 0.02 ether to Create a Collection");

    FlokiCollection  collection = new FlokiCollection(_name, _symbol,msg.sender,collectionImageUri);
    UserTocollectionsList[collectionIds++] =Collection({
      id: collectionIds,
      creator: msg.sender, 
      collectionAddress: address(collection)
    });
    
    
    
    
    // UserTocollectionsList[msg.sender]=address(collection);
    emit Collection_Created(msg.sender,address(collection));
  }  

  function Withdraw() public payable {
    require(msg.sender==owner,"only Owner can Call this Function");
    payable(msg.sender).transfer(msg.value);
  }

  function getUserNft(address user_address)public view returns(Item[]memory) {
    uint256 itemsCount=0;
    uint currentIndex = 0;
    //get user address
    //loop through items mapping
    for(uint256 i=0;i<_tokenIds.current();i++){
      if(Items[i+1].creator==user_address){
          itemsCount++;
      }
    }

    Item[] memory itemsarray= new Item[](itemsCount);

    for (uint i = 0; i < _tokenIds.current(); i++) {
      if (Items[i + 1].creator == msg.sender) {
        uint currentId = i + 1;
        Item storage currentItem = Items[currentId];
        itemsarray[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    //save user data in an array
    //return the array
    return itemsarray;
  }
  function getUserCollection(address user_address)public view  returns(address[]memory) {
    uint256 CollectionCount=0;
    uint currentIndex = 0;
    //get user address
    //loop through items mapping
    for(uint256 i=0;i<=collectionIds;i++){
      if(UserTocollectionsList[i+1].creator == user_address){
          CollectionCount++;
      }
      
    }
 
    address[] memory itemsarray= new address[](CollectionCount);

    for (uint i = 0; i <= collectionIds; i++) {
      if(UserTocollectionsList[i+1].creator == user_address) {
        uint currentId = i + 1;
        address  currentItem = UserTocollectionsList[currentId].collectionAddress;
        itemsarray[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    //save user data in an array
    //return the array
    return itemsarray;
  }

    function balanceofContract()public view returns(uint256){
      return address(this).balance;
    }
    
    function TransferOwnership(address _new_owner)public{
        require(msg.sender==owner,"only owner can call this function");
        owner=_new_owner;
    }
}