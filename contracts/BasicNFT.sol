pragma solidity ^0.4.15;

import './NFT.sol';

contract BasicNFT is NFT, NFTEvents {

  uint public totalTokens;

  // Array of owned tokens for a user
  mapping(address => uint[]) public ownedTokens;
  mapping(address => uint) _virtualLength;
  mapping(uint => uint) _tokenIndexInOwnerArray;

  // Mapping from token ID to owner
  mapping(uint => address) public tokenOwner;

  // Allowed transfers for a token (only one at a time)
  mapping(uint => address) public allowedTransfer;

  // Metadata associated with each token
  mapping(uint => string) public tokenMetadata;

  function totalSupply() public constant returns (uint) {
    return totalTokens;
  }

  function balanceOf(address owner) public constant returns (uint) {
    return _virtualLength[owner];
  }

  function tokenByIndex(address owner, uint index) public constant returns (uint) {
    require(index >= 0 && index < balanceOf(owner));
    return ownedTokens[owner][index];
  }
  
  function getAllTokens(address owner) public constant returns (uint[]) {
    uint size = _virtualLength[owner];
    uint[] memory result = new uint[](size);
    for (uint i = 0; i < size; i++) {
      result[i] = ownedTokens[owner][i];
    }
    return result;
  }

  function ownerOf(uint tokenId) public constant returns (address) {
    return tokenOwner[tokenId];
  }

  function transfer(address to, uint tokenId) public {
    require(msg.sender == tokenOwner[tokenId]);
    return _transfer(msg.sender, to, tokenId);
  }

  function approve(address beneficiary, uint tokenId) public {
    require(msg.sender == beneficiary);

    if (allowedTransfer[tokenId] != 0) {
      allowedTransfer[tokenId] = 0;
      TokenTransferDisallowed(tokenId, allowedTransfer[tokenId]);
    }
    allowedTransfer[tokenId] = beneficiary;
    TokenTransferAllowed(tokenId, beneficiary);
  }

  function transferFrom(address from, address to, uint tokenId) public {
    return _transfer(from, to, tokenId);
  }

  function metadata(uint tokenId) constant public returns (string) {
    return tokenMetadata[tokenId];
  }

  function updateTokenMetadata(uint tokenId, string _metadata) public {
    require(msg.sender == tokenOwner[tokenId]);
    tokenMetadata[tokenId] = _metadata;
    TokenMetadataUpdated(tokenId, msg.sender, _metadata);
  }

  function _transfer(address from, address to, uint tokenId) internal {
    require(tokenOwner[tokenId] == from || allowedTransfer[tokenId] == from);

    allowedTransfer[tokenId] = 0;
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);
    TokenTransferred(tokenId, from, to);
  }

  function _removeTokenFrom(address from, uint tokenId) internal {
    require(_virtualLength[from] > 0);

    uint length = _virtualLength[from];
    uint index = _tokenIndexInOwnerArray[tokenId];
    uint swapToken = ownedTokens[from][length - 1];

    ownedTokens[from][index] = swapToken;
    _tokenIndexInOwnerArray[swapToken] = index;
    _virtualLength[from]--;
  }

  function _addTokenTo(address owner, uint tokenId) internal {
    if (ownedTokens[owner].length == _virtualLength[owner]) {
      ownedTokens[owner].push(tokenId);
    } else {
      ownedTokens[owner][_virtualLength[owner]] = tokenId;
    }
    tokenOwner[tokenId] = owner;
    _tokenIndexInOwnerArray[tokenId] = _virtualLength[owner];
    _virtualLength[owner]++;
  }
}
