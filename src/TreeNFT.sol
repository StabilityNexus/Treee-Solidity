// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreeNFT is ERC721, Ownable {
    uint256 public nextTokenId; // Tracks the next token ID
    mapping(uint256 => string) private _tokenURIs; // Stores metadata URIs

    constructor()
      ERC721("TPP-NFT", "TPP")
      Ownable(msg.sender){}

    /**
     * @dev Mints an NFT for a planted tree.
     * @param to Address of the NFT recipient.
     * @param newTokenURI URI pointing to the tree metadata (e.g., IPFS URL).
     */
    function mint(address to, string memory newTokenURI) public onlyOwner {
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = newTokenURI;
    }

    /**
     * @dev Returns the URI for a given token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
}

