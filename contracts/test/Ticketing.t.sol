// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Ticketing} from "../src/Ticketing.sol";
import {NftTicket} from "../src/NftTicket.sol";
import {Token} from "../src/Token.sol";

contract TicketingTest is Test {
    Ticketing public ticketing;
    NftTicket public nftTicket;
    Token public token;
    
    address public artist = address(0x1);
    address public venue = address(0x2);
    address public buyer = address(0x3);
    address public buyer2 = address(0x4);
    
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18;
    
    function setUp() public {
        ticketing = new Ticketing("TicketCoin", "TKC", INITIAL_SUPPLY);
        
        token = ticketing.token();
        nftTicket = ticketing.nftTicket();
        
        deal(address(token), buyer, 10000 * 10**18);
        deal(address(token), buyer2, 10000 * 10**18);
        deal(address(token), address(this), 10000 * 10**18);
    }
    
    // Test 1: Créer un artiste
    function test_CreateArtist() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        
        (string memory name, string memory artistType, uint256 ticketsSold, address artistAddr) = ticketing.artists_list(0);
        
        assertEq(name, "Drake");
        assertEq(artistType, "Rapper");
        assertEq(ticketsSold, 0);
        assertEq(artistAddr, artist);
    }
    
    // Test 2: Créer un venue
    function test_CreateVenue() public {
        ticketing.createVenue("Stade de France", 80000, 20, venue);
        
        (string memory name, uint256 space, uint8 percentage, address venueAddr) = ticketing.venues_list(0);
        
        assertEq(name, "Stade de France");
        assertEq(space, 80000);
        assertEq(percentage, 20);
        assertEq(venueAddr, venue);
    }
    
    // Test 3: Créer un concert
    function test_CreateConcert() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 80000, 20, venue);
        
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        (uint256 date, uint256 artistId, uint256 venueId) = ticketing.concerts_list(0);
        
        assertEq(date, concertDate);
        assertEq(artistId, 0);
        assertEq(venueId, 0);
    }
    
    // Test 4: Émettre un ticket
    function test_EmitTicket() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitTicket(0, 100 * 10**18);
        
        assertEq(nftTicket.ownerOf(0), artist);
        assertEq(ticketing.ticketsSoldPerConcert(0), 1);
    }
    
    // Test 5: Acheter un ticket
    function test_BuyTicket() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitTicket(0, 100 * 10**18);
        
        vm.prank(artist);
        nftTicket.approve(address(ticketing), 0);
        
        vm.prank(artist);
        ticketing.sellTicket(0, 100 * 10**18);
        
        vm.prank(buyer);
        token.approve(address(ticketing), 100 * 10**18);
        
        vm.prank(buyer);
        ticketing.buyTicket(0);
        
        assertEq(nftTicket.ownerOf(0), buyer);
        assertEq(ticketing.poolPerConcert(0), 100 * 10**18);
    }
    
    // Test 6: Cash out après le concert
    function test_CashOut() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitTicket(0, 100 * 10**18);
        
        vm.prank(artist);
        nftTicket.approve(address(ticketing), 0);
        
        vm.prank(artist);
        ticketing.sellTicket(0, 100 * 10**18);
        
        vm.prank(buyer);
        token.approve(address(ticketing), 100 * 10**18);
        
        vm.prank(buyer);
        ticketing.buyTicket(0);
        
        vm.warp(concertDate + 1 days);
        
        uint256 artistBalanceBefore = token.balanceOf(artist);
        uint256 venueBalanceBefore = token.balanceOf(venue);
        
        ticketing.cashOut(0);
        
        assertEq(token.balanceOf(venue) - venueBalanceBefore, 20 * 10**18);
        assertEq(token.balanceOf(artist) - artistBalanceBefore, 80 * 10**18);
        assertEq(ticketing.poolPerConcert(0), 0);
    }
    
    // Test 7: Redemption ticket
    function test_RedeemTicket() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitRedeemableTicket(0, "SECRET123");
        
        vm.prank(buyer);
        ticketing.redeemTicket(0, "SECRET123");
        
        assertEq(nftTicket.ownerOf(0), buyer);
        assertEq(nftTicket.ticketRedeemed(0), true);
    }
    
    // Test 8: Redemption avec mauvais code (doit échouer)
    function test_RevertWhen_RedeemTicketWrongCode() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitRedeemableTicket(0, "SECRET123");
        
        vm.prank(buyer);
        vm.expectRevert("Invalid redeem code");
        ticketing.redeemTicket(0, "WRONGCODE");
    }
    
    // Test 9: Vendre plus cher que le prix d'origine (doit échouer)
    function test_RevertWhen_SellTicketTooExpensive() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitTicket(0, 100 * 10**18);
        
        vm.prank(artist);
        vm.expectRevert("Cannot sell for more than original price");
        ticketing.sellTicket(0, 200 * 10**18);
    }
    
    // Test 10: Use ticket dans les 24h avant le concert
    function test_UseTicket() public {
        ticketing.createArtist("Drake", "Rapper", 0, artist);
        ticketing.createVenue("Stade de France", 100, 20, venue);
        uint256 concertDate = block.timestamp + 30 days;
        ticketing.createConcert(concertDate, 0, 0);
        
        vm.prank(artist);
        ticketing.emitTicket(0, 100 * 10**18);
        
        vm.prank(artist);
        nftTicket.transferFrom(artist, buyer, 0);
        
        vm.warp(concertDate - 12 hours);
        
        vm.prank(buyer);
        ticketing.useTicketFromTicketing(0);
        
        (, , bool used, , ) = nftTicket.ticketInfos(0);
        assertEq(used, true);
    }
}