// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/TreeNFT.sol";

contract TreeNFTTest is Test {
    TreeNFT public treeNFT;
    address public owner;
    address public recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);

        // Deploy the TreeNFT contract
        treeNFT = new TreeNFT();
    }

    function testMintNFT() public {
        string memory tokenURI = "ipfs://examplemetadata";

        uint256 tokenId = treeNFT.nextTokenId();

        treeNFT.mint(recipient, tokenURI);

        // Verify that the token URI is correctly set for the minted token
        assertEq(treeNFT.tokenURI(tokenId), tokenURI);

        // Verify that the nextTokenId has been incremented correctly
        assertEq(treeNFT.nextTokenId(), tokenId + 1);
    }

    function testOnlyOwnerCanMint() public {
        string memory tokenURI = "ipfs://examplemetadata";

        // Simulate minting from the recipient (non-owner)
        vm.prank(recipient);
        // Expect revert due to the onlyOwner modifier
        vm.expectRevert();

        // Attempt to mint an NFT (should fail)
        treeNFT.mint(recipient, tokenURI);
    }
}
