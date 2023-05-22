// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FlokiCollection is ERC721{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  uint public noOfItems;
  address public owner;
  string public contractImage;

  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
  }

  mapping(uint256 => Item) public Items; //id => Item

  constructor (
      string memory _name,
      string memory _symbol,
      address _artist,
      string memory _contractImageUri
  ) ERC721(_name, _symbol) {
    owner=_artist;
    contractImage=_contractImageUri;
  }

  function mint(string memory uri) public returns (uint256){
    require(msg.sender==owner,"Only Collection Owner");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    noOfItems++;
    _safeMint(msg.sender, newItemId);

    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri
    });

    return newItemId;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function getUserNft(address user_address)public view returns(Item[]memory) {
    uint itemsCount=0;
    uint currentIndex = 0;
    //get user address
    //loop through items mapping
    for(uint i=0;i<_tokenIds.current();i++){
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

 

}