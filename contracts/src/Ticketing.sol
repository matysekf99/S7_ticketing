// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {NftTicket} from "../src/NftTicket.sol";
import {Token} from "../src/Token.sol";

contract Ticketing {
    struct Artist{
        string name;
        string type_artist;
        uint256 tickets_sold;
        address artist_address;
    }

    struct Venue{
        string name;
        uint256 space;
        uint8 porcentage;
        address venue_address;
    }

    struct Concert{
        uint256 date;
        uint256 artist_id;
        uint256 venue_id; 
    }

    Artist [] public artists_list;

    Venue [] public venues_list;

    Concert [] public concerts_list;

    NftTicket public nftTicket;

    Token public token;

    mapping(uint256 => uint256) public ticketsSoldPerConcert;

    mapping(uint256=> uint256) public poolPerConcert;

    mapping(uint256 => uint256) public ticketSalePrice;

    constructor(string memory tokenName, string memory tokenSymbol, uint256 initialSupply) {
        token = new Token(initialSupply,tokenName, tokenSymbol);
        nftTicket = new NftTicket("Concert Ticket","CT",address(this));
    }

    function createArtist(string memory name, string memory type_artist, uint256 tickets_sold, address artist_address) public {
        artists_list.push(Artist(name,type_artist,tickets_sold,artist_address));
    }

    function updateArtist(uint256 index, string memory name, string memory type_artist) public {
        require(index<artists_list.length,"index not in the list");
        Artist storage artist = artists_list[index];
        artist.name = name;
        artist.type_artist = type_artist;
    }

    function createVenue(string memory name, uint256 space, uint8 porcentage, address venue_address) public {
        require(porcentage <= 100, "Percentage must be <= 100"); 
        venues_list.push(Venue(name,space,porcentage,venue_address));
    }

    function updateVenue(uint256 index, string memory name, uint256 space, uint8 porcentage) public {
        require(index<venues_list.length,"index not in the list");
        require(porcentage <= 100, "Percentage must be <= 100");
        Venue storage venue = venues_list[index];
        venue.name = name;
        venue.space = space;
        venue.porcentage = porcentage;
    }

    function createConcert(uint256 date, uint256 artist_id, uint256 venue_id) public {
        require(artist_id < artists_list.length, "Artist does not exist");
        require(venue_id < venues_list.length, "Venue does not exist");
        concerts_list.push(Concert(date, artist_id, venue_id));
    }

    function emitTicket(uint256 concertId, uint256 price) public{
        require(concertId < concerts_list.length, "Concert does not exist");

        uint256 venueId = concerts_list[concertId].venue_id;
        uint256 maxSpace = venues_list[venueId].space;
        require(ticketsSoldPerConcert[concertId] < maxSpace, "Venue is full");
    
        uint256 tokenId = nftTicket.mintTicket(msg.sender, concertId, price);

        ticketSalePrice[tokenId] = price;
        ticketsSoldPerConcert[concertId]++;
    }

    function transferTicket(address to, uint256 tokenId) public {
        nftTicket.transferFrom(msg.sender, to, tokenId);
    }

    function buyTicket(uint256 tokenId) public {
        address seller = nftTicket.ownerOf(tokenId);
        (uint256 concertId, , bool used, ,) = nftTicket.ticketInfos(tokenId);
        uint256 sell_price = ticketSalePrice[tokenId];
        require(!used, "Ticket already used");
        require(token.transferFrom(msg.sender, address(this), sell_price), "Token transfer failed");
        poolPerConcert[concertId] += sell_price;
        nftTicket.safeTransferFrom(seller, msg.sender, tokenId);
    }


    function cashOut(uint256 concertId) public {
        require(block.timestamp > concerts_list[concertId].date, "Concert not passed");
        
        uint256 porcentage_venue = venues_list[concerts_list[concertId].venue_id].porcentage;
        uint256 total_pool = poolPerConcert[concertId];
        require(total_pool > 0, "No funds to cash out");

        uint256 send_to_venue = total_pool * porcentage_venue / 100;
        uint256 send_to_artist = total_pool - send_to_venue;

        address artist_address = artists_list[concerts_list[concertId].artist_id].artist_address;
        address venue_address = venues_list[concerts_list[concertId].venue_id].venue_address;

        token.transfer(artist_address, send_to_artist);
        token.transfer(venue_address, send_to_venue);

        poolPerConcert[concertId] = 0;
    }


    function sellTicket(uint256 tokenId, uint256 salePrice) public {
        require(nftTicket.ownerOf(tokenId) == msg.sender, "Not the owner");
        
        (, uint256 originalPrice, , ,) = nftTicket.ticketInfos(tokenId);
        require(salePrice <= originalPrice, "Cannot sell for more than original price");
        
        ticketSalePrice[tokenId] = salePrice;
    }

    function emitRedeemableTicket(uint256 concertId, string memory redeemCode) public {
        require(concertId < concerts_list.length, "Concert does not exist");
        uint256 venueId = concerts_list[concertId].venue_id;
        uint256 maxSpace = venues_list[venueId].space;

        require(ticketsSoldPerConcert[concertId] < maxSpace, "Venue is full");
        uint256 tokenId = nftTicket.createRedeemableTicket(concertId, redeemCode);
        ticketsSoldPerConcert[concertId]++;
        ticketSalePrice[tokenId] = 0;
    }

    function redeemTicket(uint256 tokenId, string memory redeemCode) public {
        nftTicket.redeemTicket(tokenId, redeemCode, msg.sender);
    }

    function useTicketFromTicketing(uint256 tokenId) public {
        nftTicket.useTicket(tokenId, msg.sender);
    }
}

