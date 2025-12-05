// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ITicketing {
    struct Concert {
        uint256 date;
        uint256 artist_id;
        uint256 venue_id;
    }
    
    function concerts_list(uint256 index) external view returns (Concert memory);
}

contract NftTicket is ERC721 {
    uint256 private _nextTokenId;

    address public ticketingContract;
    
    struct TicketInfo {
        uint256 concertId;
        uint256 price;
        bool used;
        bool isRedeemable;
        bytes32 redeemCodeHash; 
    }
    
    mapping(uint256 => TicketInfo) public ticketInfos;

    mapping(uint256 => bool) public ticketExists;

    mapping(uint256 => bool) public ticketRedeemed;
    
    constructor(string memory name, string memory symbol, address _ticketingContract) ERC721(name, symbol) {
        ticketingContract = _ticketingContract;
    }

    function mintTicket(address to, uint256 concertId, uint256 price) public returns (uint256){
        require(msg.sender == ticketingContract, "Only ticketing contract can mint");

        uint256 tokenId = _nextTokenId;
        _mint(to, tokenId);
        
        ticketInfos[tokenId] = TicketInfo({
            concertId: concertId,
            price: price,
            used: false,
            isRedeemable: false,
            redeemCodeHash: bytes32(0) 
        });

        ticketExists[tokenId] = true;
        _nextTokenId++;
        return tokenId;
    }

    function useTicket(uint256 tokenId, address user) public {
        require(msg.sender == ticketingContract, "Only ticketing contract can use");
        require(ownerOf(tokenId) == user, "Not the owner");
        require(!ticketInfos[tokenId].used, "Ticket already used");

        ITicketing.Concert memory concert = ITicketing(ticketingContract).concerts_list(ticketInfos[tokenId].concertId);
        uint256 concertDate = concert.date;

        require(block.timestamp >= concertDate - 24 hours, "Too early");
        require(block.timestamp < concertDate, "Concert already passed");

        ticketInfos[tokenId].used = true;
    }


    function createRedeemableTicket(uint256 concertId, string memory redeemCode) public returns (uint256) {
        require(msg.sender == ticketingContract, "Only ticketing contract can mint");
        
        uint256 tokenId = _nextTokenId;
        
        ticketInfos[tokenId] = TicketInfo({
            concertId: concertId,
            price: 0,
            used: false,
            isRedeemable: true,
            redeemCodeHash: keccak256(abi.encodePacked(redeemCode))
        });
        ticketExists[tokenId] = true;
        _nextTokenId++;
        return tokenId;
    }


    function redeemTicket(uint256 tokenId, string memory redeemCode, address redeemer) public {
        require(msg.sender == ticketingContract, "Only ticketing contract can redeem");
        require(ticketExists[tokenId], "Ticket does not exist");
        
        TicketInfo storage ticket = ticketInfos[tokenId];
        require(ticket.isRedeemable, "Ticket is not redeemable");
        require(!ticketRedeemed[tokenId], "Ticket already redeemed");
        
        require(
            keccak256(abi.encodePacked(redeemCode)) == ticket.redeemCodeHash,
            "Invalid redeem code"
        );
        
        ticketRedeemed[tokenId] = true;
        _mint(redeemer, tokenId);
    }
}