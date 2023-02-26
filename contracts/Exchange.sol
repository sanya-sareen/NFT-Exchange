// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "contracts/interface/IExecutionDelegate.sol";
import {
    AssetType,
    Side,
    Order
} from "contracts/lib/OrderStruct.sol";

pragma solidity ^0.8.7;

contract Exchange01 is EIP712{

      string private constant SIGNING_DOMAIN = "Exchange";
      string private constant SIGNATURE_VERSION = "1";
      bytes32 public root;
      address public owner;

      IERC20 public tokenAddress;
      IExecutionDelegate public executionDelegate;

      mapping(address => uint) public feesPaid;
      mapping(address => uint) public deposits;

      event NewExecutionDelegate(IExecutionDelegate indexed executionDelegate);
    // event ExecuteOrder()
    // event WhiteListed()
    // event Deposit()
    // event Withdraw()

      modifier onlyOwner(){
          require(msg.sender == owner, "Not owner");
          _;
      }

    constructor(address _tokenAddress, bytes32 _root, address _executionDelegate) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        root = _root;
        executionDelegate = IExecutionDelegate(_executionDelegate);
        tokenAddress = IERC20(_tokenAddress);
        owner = msg.sender;
    }

    function deposit(uint _amount) public {
        tokenAddress.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] = _amount;
    }

    // amount - fees
    function withdraw() public{
        uint withdrawAmnt = deposits[msg.sender] - feesPaid[msg.sender];
        tokenAddress.transfer(msg.sender, withdrawAmnt);
    }

    function _validateOrder(Order calldata order) internal  view returns(bool){
        return (order.trader != address(0) && order.listingTime < block.timestamp);
    }

    // check asset type
    // signature for order
    function executeOrder(Order calldata order,
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint _fees
        ) public returns(bool){

        require(deposits[msg.sender] > _fees, "Not part of allowlist");
        require(_validateOrder(order), "order not valid");
        require(_verify(order),"wrong user signature");
        
        _delegateTransfer(collection,from,to,tokenId);
        feesPaid[msg.sender] = _fees;

        return true;
    }

    function setExecution(address _executionDelegate) public onlyOwner{
        require(address(_executionDelegate) != address(0), "Address cannot be zero");
        executionDelegate = IExecutionDelegate(_executionDelegate);
        emit NewExecutionDelegate(executionDelegate);
    }

    //  Signature for order
    function recover(Order calldata order) public view returns(address){
         bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Order(address trader,uint256 tokenId,address collection,uint256 listingTime,uint256 price)"),
            order.trader,
            order.tokenId,
            order.collection,
            order.listingTime,
            order.price
        )));
        address signer = ECDSA.recover(digest, order.signature);
        return signer;
    }

    function _verify(Order calldata order) internal view returns(bool){
         if (msg.sender == recover(order)){
             return true;
         }
         return false;
    }

    function _delegateTransfer(address collection,
        address from,
        address to,
        uint256 tokenId) internal{
            executionDelegate.transferERC721(collection, from, to, tokenId);
        }

    function _isValid(bytes32[] memory proof, bytes32 leaf) internal view returns(bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function whiteListUser(bytes32[] memory proof) public view returns(bool){
        require(_isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not valid");
        return true;
    }

    
}