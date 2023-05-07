// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "src/NFT.sol";
import "forge-std/Test.sol";

contract NFTTest is Test {
    NFT nft= new NFT(10, 1000000000, 6, IERC20(0xb637E978D7661Ff540B845C70CE84Ce448B16902));
    
    // function testMintNFT() public {
    //     nft.buyCallOption(1);
    //     nft.buyCallOption(2);
    //     assert(nft.getCallOption()==3);
    //     nft.auctionmintNFT(3);
    //     assert(nft.ownerOf(1)==msg.sender);
    //     assert(nft.ownerOf(2)==msg.sender);
    //     assert(nft.balanceOf(msg.sender)== 3);
    // }
    function testMint() public {
        uint256 initialBalance = nft.balanceOf(msg.sender);
        vm.prank(msg.sender);
        nft.buyCallOption(3);
        nft.setAuction(100, 60, 1 ether, 1 ether, 10);
        vm.prank(msg.sender);
        nft.auctionmintNFT(1);
        uint256 newBalance = nft.balanceOf(msg.sender);
        assert(newBalance == initialBalance + 1);
    }

    function testEnterTicket() public {
        vm.prank(msg.sender);
        nft.buyCallOption(1);
        nft.setAuction(100, 60, 1 ether, 1 ether, 10);
        vm.prank(msg.sender);
        nft.auctionmintNFT(1);
        vm.prank(msg.sender);
        assert(nft.used_Ticket(1) ==false);
        nft.enterTicket(1);
        vm.prank(msg.sender);
        bool used = nft.used_Ticket(1);
        assert(used ==true);
    }

    function testTokenURI() public {
        vm.prank(msg.sender);
        nft.buyCallOption(1);
        nft.setAuction(100, 60, 1 ether, 1 ether, 10);
        vm.prank(msg.sender);
        nft.auctionmintNFT(1);
        vm.prank(msg.sender);
        string memory actual = nft.tokenURI(1);
        string memory expected = "https://gateway.pinata.cloud/ipfs/QmdDzL4Rb2JLcJdQPtNuCJSZ5TTZKwYJXbbjyqVq49iyyL/ticket.json";
        bytes32 expectedHash = keccak256(abi.encodePacked(expected));
        bytes32 actualHash = keccak256(abi.encodePacked(actual));
        assert(expectedHash == actualHash );
    }

    function testBuyCallOption() public {
        uint256 initialBalance = nft.pointBalances(address(this));
        nft.buyCallOption(3);
        uint256 newBalance = nft.pointBalances(address(this));
        assert(newBalance==initialBalance + 3);
    }

    function testGetCallOption() public {
        nft.buyCallOption(3);
        uint256 points = nft.getCallOption();
        assert(points == 3);
    }

    function testSetAuction() public {
        nft.setAuction(100, 60, 1 ether, 1 ether, 10);
        uint256 price = nft.getAuctionPrice();
        uint256 price2 = 1000000000;
        assert(price==price2);
    }
    // vm.stopPrank("0x9DB36029198CD3Dc70DE207be6918558AB0b70ea")
}
