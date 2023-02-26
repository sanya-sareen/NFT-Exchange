// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum AssetType  {ERC721, ERC1155}
enum Side { Buy, Sell }

struct Order{
    address trader;
    uint256 tokenId;
    address collection;
    uint256 listingTime;
    uint256 price;
    bytes signature;
}

