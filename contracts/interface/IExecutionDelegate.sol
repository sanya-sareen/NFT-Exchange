// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IExecutionDelegate {
    function revokeApproval() external;
    function approveContract(address _contract) external;
    function transferERC721(address collection, address from, address to, uint256 tokenId) external;
    // function transferERC1155()
}