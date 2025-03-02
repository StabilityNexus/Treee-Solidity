// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/TreeeNFT.sol"; // Ensure this matches your actual directory structure
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract TreeNFTTest is Test, IERC721Receiver {
    TreeNft treeNFT;

    function setUp() public {
        treeNFT = new TreeNft();
    }

    function testGetAllNFTs() public {
        // Mint two NFTs to this contract
        treeNFT.mintNft(123456, 654321, "Oak", "https://ipfs.io/ipfs/Qm1");
        treeNFT.mintNft(789012, 210987, "Pine", "https://ipfs.io/ipfs/Qm2");

        // Call getAllNFTs()
        string[] memory allNFTs = treeNFT.getAllNFTs();

        // Ensure two NFTs are returned
        assertEq(allNFTs.length, 2);

        // Check if the returned string contains expected values
        assertTrue(_contains(allNFTs[0], "123456"), "Latitude incorrect");
        assertTrue(_contains(allNFTs[0], "654321"), "Longitude incorrect");
        assertTrue(_contains(allNFTs[0], "Oak"), "Species incorrect");
        assertTrue(_contains(allNFTs[0], "https://ipfs.io/ipfs/Qm1"), "Image URI incorrect");

        assertTrue(_contains(allNFTs[1], "789012"), "Latitude incorrect");
        assertTrue(_contains(allNFTs[1], "210987"), "Longitude incorrect");
        assertTrue(_contains(allNFTs[1], "Pine"), "Species incorrect");
        assertTrue(_contains(allNFTs[1], "https://ipfs.io/ipfs/Qm2"), "Image URI incorrect");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _contains(string memory mainStr, string memory subStr) private pure returns (bool) {
        return bytes(mainStr).length >= bytes(subStr).length && _indexOf(mainStr, subStr) != -1;
    }

    function _indexOf(string memory haystack, string memory needle) private pure returns (int256) {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        if (needleBytes.length > haystackBytes.length) return -1;

        for (uint256 i = 0; i <= haystackBytes.length - needleBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < needleBytes.length; j++) {
                if (haystackBytes[i + j] != needleBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return int256(i);
        }
        return -1;
    }
}
