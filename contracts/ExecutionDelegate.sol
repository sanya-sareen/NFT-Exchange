
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IExecutionDelegate} from "contracts/interface/IExecutionDelegate.sol";

pragma solidity ^0.8.7;

contract ExecutionDelegate is IExecutionDelegate{
    using Address for address;

    mapping(address => bool) public contracts;
    mapping(address => bool) public revokedApproval;

    modifier approvedContract(){
        require(contracts[msg.sender],"contract is not approved to make transfers");
        _;
    }
     
    function approveContract(address _contract) external override {
        contracts[_contract] = true;
    }

    function revokeApproval() external override {
         revokedApproval[msg.sender] = true;
    }
    
    function transferERC721(address collection, address from, address to, uint256 tokenId)external  override approvedContract{
         require(revokedApproval[from] == false, "User has revoked approval");
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }


}
/**
* nft contract approved execution contract to make transfers
approve(address to is of execution contract) -- erc721 contract
in exchange from is owner of nft collection-erc721
*/