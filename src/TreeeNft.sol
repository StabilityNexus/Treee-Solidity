// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./TreeVerificationContract.sol";
import  "./UserActivityContract.sol";

import "./utils/structs.sol";
import "./utils/errors.sol";

contract TreeNft is ERC721, Ownable {
    uint256 private s_tokenCounter;
    uint256 private s_organisationCounter;
    uint256 private s_deathCounter;
    mapping(uint256 => Tree) private s_tokenIDtoTree;
    mapping(uint256 => address[]) private s_tokenIDtoVerifiers;
    mapping(address => uint256[]) private s_userToNFTs;
    mapping(uint256 => mapping(address => bool)) private s_tokenIDtoUserVerification;
    mapping(address => uint256[]) private s_verifierToTokenIDs;

    constructor() Ownable(msg.sender) ERC721("TreeNFT", "TREE") {
        s_tokenCounter = 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < s_tokenCounter && tokenId >= 0;
    }

    // Mint a new Tree NFT with a custom image URI
    function mintNft(
        uint256 latitude, 
        uint256 longitude, 
        string memory species, 
        string memory imageUri, 
        string memory qrIpfsHash,
        string memory geoHash,
        string[] memory initialPhotos,  // Allow passing initial photos during minting
        address organisationAddress
    ) public {
        uint256 tokenId = s_tokenCounter;
        _safeMint(msg.sender, tokenId);
        address[] memory ancestors = new address[](1);
        ancestors[0] = msg.sender;
        Verification[] memory emptyVerifications = new Verification[](0);
        s_tokenIDtoTree[tokenId] = Tree(
            latitude,
            longitude,
            block.timestamp,
            type(uint256).max, 
            species,
            imageUri,
            qrIpfsHash,
            initialPhotos, 
            geoHash,
            ancestors,
            organisationAddress,
            emptyVerifications,
            block.timestamp,
            0
        );
        s_userToNFTs[msg.sender].push(tokenId);
        s_tokenCounter++;
    }

    function markDead(uint256 tokenId) public {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if(s_tokenIDtoTree[tokenId].death != type(uint256).max) revert TreeAlreadyDead();
        if(ownerOf(tokenId) != msg.sender) revert NotTreeOwner();
        s_tokenIDtoTree[tokenId].death = block.timestamp;
        s_deathCounter++;
    }

    function verify(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        if (!s_tokenIDtoUserVerification[tokenId][msg.sender]) {
            s_tokenIDtoUserVerification[tokenId][msg.sender] = true;
            s_tokenIDtoVerifiers[tokenId].push(msg.sender);
            s_verifierToTokenIDs[msg.sender].push(tokenId); 
        }
    }

    function isVerified(uint256 tokenId, address verifier) public view returns (bool) {
        return s_tokenIDtoUserVerification[tokenId][verifier];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        Tree memory tree = s_tokenIDtoTree[tokenId];
        string memory verifiersList = _getVerifiersString(tokenId);

        string memory json = string(
            abi.encodePacked( 
                '{"name":"TreeNFT #',
                _uintToString(tokenId),
                '", "description":"A Tree NFT for planting a tree", ',
                '"attributes": [{"trait_type": "Latitude", "value": "',
                _uintToString(tree.latitude),
                '"}, {"trait_type": "Longitude", "value": "',
                _uintToString(tree.longitude),
                '"}, {"trait_type": "Planting", "value": "',
                _uintToString(tree.planting),
                '"}, {"trait_type": "Death", "value": "',
                _uintToString(tree.death),
                '"}, {"trait_type": "Verifiers", "value": "',
                verifiersList,
                '"}], "image":"',
                tree.imageUri, // Use custom image URI
                '"}'
            )
        );
        return string(abi.encodePacked(_baseURI(), Base64.encode(bytes(json))));
    }

    function getAllNFTs() public view returns (string[] memory) {
        string[] memory allNFTs = new string[](s_tokenCounter);

        for (uint256 tokenId = 0; tokenId < s_tokenCounter; tokenId++) {
            Tree memory tree = s_tokenIDtoTree[tokenId];
            string memory verifiersList = _getVerifiersString(tokenId);

            string memory nftDetails = string(
                abi.encodePacked(
                    '{"tokenId": "',
                    _uintToString(tokenId),
                    '", "latitude": "',
                    _uintToString(tree.latitude),
                    '", "longitude": "',
                    _uintToString(tree.longitude),
                    '", "species": "',
                    tree.species,
                    '", "planting": "',
                    _uintToString(tree.planting),
                    '", "death": "',
                    _uintToString(tree.death),
                    '", "verifiers": "',
                    verifiersList,
                    '", "imageUri": "',
                    tree.imageUri,
                    '", "tokenURI": "',
                    tokenURI(tokenId),
                    '"}'
                )
            );

            allNFTs[tokenId] = nftDetails;
        }

        return allNFTs;
    }

    function getNFTsByUser(address user) public view returns (string[] memory) {
        uint256[] memory userNFTs = s_userToNFTs[user];
        string[] memory nftDetails = new string[](userNFTs.length);

        for (uint256 i = 0; i < userNFTs.length; i++) {
            uint256 tokenId = userNFTs[i];
            Tree memory tree = s_tokenIDtoTree[tokenId];
            string memory verifiersList = _getVerifiersString(tokenId);

            nftDetails[i] = string(
                abi.encodePacked(
                    '{"tokenId": "',
                    _uintToString(tokenId),
                    '", "latitude": "',
                    _uintToString(tree.latitude),
                    '", "longitude": "',
                    _uintToString(tree.longitude),
                    '", "species": "',
                    tree.species,
                    '", "planting": "',
                    _uintToString(tree.planting),
                    '", "death": "',
                    _uintToString(tree.death),
                    '", "verifiers": "',
                    verifiersList,
                    '", "imageUri": "',
                    tree.imageUri,
                    '", "tokenURI": "',
                    tokenURI(tokenId),
                    '"}'
                )
            );
        }

        return nftDetails;
    }
    function getVerifiedTreesByUser(address verifier) public view returns (string[] memory) {
        uint256[] memory verifiedTokens = s_verifierToTokenIDs[verifier];
        string[] memory treeDetails = new string[](verifiedTokens.length);
        
        for (uint256 i = 0; i < verifiedTokens.length; i++) {
            uint256 tokenId = verifiedTokens[i];
            Tree memory tree = s_tokenIDtoTree[tokenId];
            
            // Format the tree information similar to other view functions
            treeDetails[i] = string(
                abi.encodePacked(
                    '{"tokenId": "',
                    _uintToString(tokenId),
                    '", "latitude": "',
                    _uintToString(tree.latitude),
                    '", "longitude": "',
                    _uintToString(tree.longitude),
                    '", "species": "',
                    tree.species,
                    '", "planting": "',
                    _uintToString(tree.planting),
                    '", "death": "',
                    _uintToString(tree.death),
                    '", "imageUri": "',
                    tree.imageUri,
                    '"}'
                )
            );
        }
        
        return treeDetails;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _getVerifiersString(uint256 tokenId) private view returns (string memory) {
        address[] memory verifiers = s_tokenIDtoVerifiers[tokenId];
        uint256 length = verifiers.length;

        if (length == 0) {
            return "None";
        }

        string memory verifiersList = _addressToString(verifiers[0]);

        for (uint256 i = 1; i < length; i++) {
            verifiersList = string(abi.encodePacked(verifiersList, ", ", _addressToString(verifiers[i])));
        }

        return verifiersList;
    }


    function _uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _addressToString(address addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
