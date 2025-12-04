// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {NftTicket} from "../src/NftTicket.sol";
import {Token} from "../src/Token.sol";

contract Ticketing {
    struct Artist{
        string name;
        string type_artist;
        uint256 tickets_sold;
    }

    struct Venue{
        string name;
        uint256 space;
        uint8 porcentage;
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

    constructor(string memory tokenName, string memory tokenSymbol, uint256 initialSupply) {
        token = new Token(initialSupply,tokenName, tokenSymbol);
        nftTicket = new NftTicket("Concert Ticket","CT",address(this));
    }

    function createArtist(string memory name, string memory type_artist, uint256 tickets_sold) public {
        artists_list.push(Artist(name,type_artist,tickets_sold));
    }

    function updateArtist(uint256 index, string memory name, string memory type_artist, uint256 tickets_sold) public {
        require(index<artists_list.length,"index not in the list");
        Artist storage artist = artists_list[index];
        artist.name = name;
        artist.type_artist = type_artist;
        artist.tickets_sold = tickets_sold;
    }

    function createVenue(string memory name, uint256 space, uint8 porcentage) public {
        require(porcentage <= 100, "Percentage must be <= 100"); 
        venues_list.push(Venue(name,space,porcentage));
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
        
        nftTicket.mintTicket(msg.sender, concertId, price);
    }
}

