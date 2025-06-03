// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./utils/structs.sol";
import "./utils/errors.sol";

contract TreeNft is ERC721, Ownable {
    uint256 private s_tokenCounter;
    uint256 private s_organisationCounter;
    uint256 private s_deathCounter;
    uint256 private s_treeNftVerification;
    uint256 private s_userCounter;

    mapping(uint256 => Tree) private s_tokenIDtoTree;
    mapping(uint256 => address[]) private s_tokenIDtoVerifiers;
    mapping(address => uint256[]) private s_userToNFTs;

    mapping(uint256 => mapping(address => bool)) private s_tokenIDtoUserVerification;
    mapping(address => uint256[]) private s_verifierToTokenIDs;
    mapping(uint256 => TreeNftVerification) private s_tokenIDtoTreeNftVerfication;
    mapping(uint256 => uint256[]) private s_treeTokenIdToVerifications;

    mapping(address => User) s_addressToUser;

    constructor() Ownable(msg.sender) ERC721("TreeNFT", "TREE") {
        s_tokenCounter = 0;
        s_organisationCounter = 0;
        s_deathCounter = 0;
        s_treeNftVerification = 0;
        s_userCounter = 0;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < s_tokenCounter && tokenId >= 0;
    }

    function mintNft(
        uint256 latitude,
        uint256 longitude,
        string memory species,
        string memory imageUri,
        string memory qrIpfsHash,
        string memory geoHash,
        string[] memory initialPhotos, // Allow passing initial photos during minting
        address organisationAddress
    ) public {
        // This function mints a new NFT for the user

        uint256 tokenId = s_tokenCounter;
        s_tokenCounter++;
        s_userToNFTs[msg.sender].push(tokenId);
        _mint(msg.sender, tokenId);
        address[] memory ancestors = new address[](1);
        ancestors[0] = msg.sender;
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
            block.timestamp,
            0
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        
        if (!_exists(tokenId)) revert InvalidTreeID();
        Tree memory tree = s_tokenIDtoTree[tokenId];

        string memory json = string(
            abi.encodePacked(
                '{"name":"TreeNFT #',
                Strings.toString(tokenId),
                '","description":"Tree planted at coordinates ',
                Strings.toString(tree.latitude),
                ",",
                Strings.toString(tree.longitude),
                '","image":"',
                tree.imageUri,
                '","attributes":[{"trait_type":"Latitude","value":',
                Strings.toString(tree.latitude),
                '},{"trait_type":"Longitude","value":',
                Strings.toString(tree.longitude),
                '},{"trait_type":"Planting Date","value":',
                Strings.toString(tree.planting),
                "}]}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function getAllNFTs() public view returns (Tree[] memory) {
        // This function retrieves all NFTs in the contract

        Tree[] memory allTrees = new Tree[](s_tokenCounter);
        for (uint256 i = 0; i < s_tokenCounter; i++) {
            allTrees[i] = s_tokenIDtoTree[i];
        }
        return allTrees;
    }

    function getRecentTreesPaginated(uint256 offset, uint256 limit)
        external
        view
        returns (Tree[] memory paginatedTrees, uint256 totalCount, bool hasMore)
    {
        // This function retrieves recent trees with pagination

        if (limit > 50) revert PaginationLimitExceeded();
        uint256 totalTrees = s_tokenCounter;
        if (offset >= totalTrees) return (new Tree[](0), totalTrees, false);
        uint256 available = totalTrees - offset;
        uint256 toReturn = available < limit ? available : limit;
        Tree[] memory result = new Tree[](toReturn);
        for (uint256 i = 0; i < toReturn; i++) {
            uint256 treeIndex = totalTrees - 1 - offset - i;
            result[i] = s_tokenIDtoTree[treeIndex];
        }
        bool hasMoreTrees = offset + toReturn < totalTrees;
        return (result, totalTrees, hasMoreTrees);
    }

    function getNFTsByUser(address user) public view returns (Tree[] memory) {
        // This function retrieves all NFTs owned by a specific user

        uint256[] memory userNFTs = s_userToNFTs[user];
        Tree[] memory userTrees = new Tree[](userNFTs.length);
        for (uint256 i = 0; i < userNFTs.length; i++) {
            uint256 tokenId = userNFTs[i];
            userTrees[i] = s_tokenIDtoTree[tokenId];
        }
        return userTrees;
    }

    function getTreeDetailsbyID(uint256 tokenId) public view returns (Tree memory) {
        // This function retrieves details of a specific tree NFT by its ID

        if (!_exists(tokenId)) revert InvalidTreeID();
        return s_tokenIDtoTree[tokenId];
    }

    function verify(uint256 _tokenId, string[] memory _proofHashes, string memory _description) public {
        // This function allows a verifier to verify a tree

        if (!_exists(_tokenId)) revert InvalidTreeID();
        TreeNftVerification memory treeVerification =
            TreeNftVerification(msg.sender, block.timestamp, _proofHashes, _description, false, _tokenId);
        if (!_isVerified(_tokenId, msg.sender)) {
            s_tokenIDtoUserVerification[_tokenId][msg.sender] = true;
            s_tokenIDtoVerifiers[_tokenId].push(msg.sender);
            s_verifierToTokenIDs[msg.sender].push(_tokenId);
            s_tokenIDtoTreeNftVerfication[s_treeNftVerification] = treeVerification;
            s_treeTokenIdToVerifications[_tokenId].push(s_treeNftVerification);
            s_treeNftVerification++;
        }
    }

    function removeVerification(uint256 _verificationId) public {
        // This function enables the owner of the NFT to remove verifications as he pleases (in case of fraudalent verification spam)

        TreeNftVerification memory treeNftVerification = s_tokenIDtoTreeNftVerfication[_verificationId];
        if (msg.sender != ownerOf(treeNftVerification.treeNftId)) revert NotTreeOwner();
        treeNftVerification.isHidden = true;
        User memory user = s_addressToUser[treeNftVerification.verifier];
        user.verificationsRevoked++;
    }

    function getVerifiedTreesByUser(address verifier) public view returns (Tree[] memory) {
        // This function retrieves all trees verified by a specific verifier

        uint256[] memory verifiedTokens = s_verifierToTokenIDs[verifier];
        Tree[] memory verifiedTrees = new Tree[](verifiedTokens.length);
        for (uint256 i = 0; i < verifiedTokens.length; i++) {
            uint256 tokenId = verifiedTokens[i];
            verifiedTrees[i] = s_tokenIDtoTree[tokenId];
        }
        return verifiedTrees;
    }

    function getTreeNftVerifiers(uint256 _tokenId) public view returns (TreeNftVerification[] memory) {
        // This function returns the verifiers of a particular TreeNFT

        uint256[] storage verificationIds = s_treeTokenIdToVerifications[_tokenId];
        TreeNftVerification[] memory treeNftVerifications = new TreeNftVerification[](verificationIds.length);
        for (uint256 i = 0; i < verificationIds.length; i++) {
            uint256 verificationId = verificationIds[i];
            TreeNftVerification memory verification = s_tokenIDtoTreeNftVerfication[verificationId];
            if (verification.isHidden) continue;
            treeNftVerifications[i] = verification;
        }
        return treeNftVerifications;
    }

    function markDead(uint256 tokenId) public {
        // This function marks a tree as dead

        if (!_exists(tokenId)) revert InvalidTreeID();
        if (s_tokenIDtoTree[tokenId].death != type(uint256).max) revert TreeAlreadyDead();
        if (ownerOf(tokenId) != msg.sender) revert NotTreeOwner();
        s_tokenIDtoTree[tokenId].death = block.timestamp;
        s_deathCounter++;
    }

    function _isVerified(uint256 tokenId, address verifier) public view returns (bool) {
        // This function checks if a verifier has verified a tree

        return s_tokenIDtoUserVerification[tokenId][verifier];
    }

    function registerUserProfile(string memory _name, string memory _profilePhotoHash) public {
        // This function registers a user

        if (s_addressToUser[msg.sender].userAddress != address(0)) revert UserAlreadyRegistered();
        User memory user = User(msg.sender, _profilePhotoHash, _name, block.timestamp, 0, 0);
        s_addressToUser[msg.sender] = user;
        s_userCounter++;
    }

    function updateUserDetails(string memory _name, string memory _profilePhotoHash) public {
        // This function enables a user to chnage his user details

        if (s_addressToUser[msg.sender].userAddress == address(0)) revert UserNotRegistered();
        User memory user = s_addressToUser[msg.sender];
        user.name = _name;
        user.profilePhotoIpfs = _profilePhotoHash;
    }
}
