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
    }
    
    mapping(uint256 => TicketInfo) public ticketInfos;
    
    constructor(string memory name, string memory symbol, address _ticketingContract) ERC721(name, symbol) {
        ticketingContract = _ticketingContract;
    }

    function mintTicket(address to, uint256 concertId, uint256 price) public {
        require(msg.sender == ticketingContract, "Only ticketing contract can mint");

        uint256 tokenId = _nextTokenId;
        _mint(to, tokenId);
        
        ticketInfos[tokenId] = TicketInfo({
            concertId: concertId,
            price: price,
            used: false
        });
        _nextTokenId++;
    }

    function useTicket(uint256 tokenId) public {
        require(ownerOf(tokenId)==msg.sender,"Not the owner");
        require(!ticketInfos[tokenId].used,"Ticket already used");

        ITicketing.Concert memory concert = ITicketing(ticketingContract).concerts_list(ticketInfos[tokenId].concertId);
        uint256 concertDate = concert.date;

        require(block.timestamp >= concertDate - 24 hours, "Too early");
        require(block.timestamp < concertDate, "Concert already passed");


        ticketInfos[tokenId].used = true;
    }
}