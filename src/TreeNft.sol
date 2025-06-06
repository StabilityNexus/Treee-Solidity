// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "./utils/structs.sol";
import "./utils/errors.sol";

import "./Organisation.sol";
import "./OrganisationFactory.sol";

import "./token-contracts/CareToken.sol";
import "./token-contracts/LegacyToken.sol";
import "./token-contracts/PlanterToken.sol";
import "./token-contracts/VerifierToken.sol";

contract TreeNft is ERC721, Ownable {
    uint256 private s_tokenCounter;
    uint256 private s_organisationCounter;
    uint256 private s_deathCounter;
    uint256 private s_treeNftVerification;
    uint256 private s_userCounter;

    uint256 public minimumTimeToMarkTreeDead = 365 days;
    CareToken public careTokenContract;
    PlanterToken public planterTokenContract;
    VerifierToken public verifierTokenContract;
    LegacyToken public legacyToken;

    mapping(uint256 => Tree) private s_tokenIDtoTree;
    mapping(uint256 => address[]) private s_tokenIDtoVerifiers;
    mapping(address => uint256[]) private s_userToNFTs;

    mapping(uint256 => mapping(address => bool)) private s_tokenIDtoUserVerification;
    mapping(address => uint256[]) private s_verifierToTokenIDs;
    mapping(uint256 => TreeNftVerification) private s_tokenIDtoTreeNftVerfication;
    mapping(uint256 => uint256[]) private s_treeTokenIdToVerifications;

    mapping(address => User) s_addressToUser;

    constructor(
        address _careTokenContract,
        address _planterTokenContract,
        address _verifierTokenContract,
        address _legacyTokenContract
    ) Ownable(msg.sender) ERC721("TreeNFT", "TREE") {
        s_tokenCounter = 0;
        s_organisationCounter = 0;
        s_deathCounter = 0;
        s_treeNftVerification = 0;
        s_userCounter = 0;

        if (_careTokenContract == address(0)) revert InvalidInput();
        if (_planterTokenContract == address(0)) revert InvalidInput();
        if (_verifierTokenContract == address(0)) revert InvalidInput();
        if (_legacyTokenContract == address(0)) revert InvalidInput();

        careTokenContract = CareToken(_careTokenContract);
        planterTokenContract = PlanterToken(_planterTokenContract);
        verifierTokenContract = VerifierToken(_verifierTokenContract);
        legacyToken = LegacyToken(_legacyTokenContract);
    }

    event VerificationRemoved(uint256 indexed verificationId, uint256 indexed treeNftId, address indexed verifier);

    function mintNft(
        uint256 latitude,
        uint256 longitude,
        string memory species,
        string memory imageUri,
        string memory qrIpfsHash,
        string memory geoHash,
        string[] memory initialPhotos
    ) public {
        // This function mints a new NFT for the user

        if (latitude > 180 * 1e6) revert InvalidCoordinates();
        if (longitude > 360 * 1e6) revert InvalidCoordinates();

        uint256 tokenId = s_tokenCounter;
        s_tokenCounter++;
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
            block.timestamp,
            0
        );

        s_userToNFTs[msg.sender].push(tokenId);
        planterTokenContract.mint(msg.sender, tokenId);
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

    function getNFTsByUserPaginated(address user, uint256 offset, uint256 limit)
        public
        view
        returns (Tree[] memory trees, uint256 totalCount)
    {
        // Get the total number of NFTs for this user

        uint256[] memory userNFTs = s_userToNFTs[user];
        totalCount = userNFTs.length;

        if (offset >= totalCount) {
            return (new Tree[](0), totalCount);
        }
        uint256 end = offset + limit;
        if (end > totalCount) {
            end = totalCount;
        }
        uint256 resultLength = end - offset;
        trees = new Tree[](resultLength);
        for (uint256 i = 0; i < resultLength; i++) {
            uint256 tokenId = userNFTs[offset + i];
            trees[i] = s_tokenIDtoTree[tokenId];
        }

        return (trees, totalCount);
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
        if (!isVerified(_tokenId, msg.sender)) {
            s_tokenIDtoUserVerification[_tokenId][msg.sender] = true;
            s_tokenIDtoVerifiers[_tokenId].push(msg.sender);
            s_verifierToTokenIDs[msg.sender].push(_tokenId);
            s_tokenIDtoTreeNftVerfication[s_treeNftVerification] = treeVerification;
            s_treeTokenIdToVerifications[_tokenId].push(s_treeNftVerification);
            s_treeNftVerification++;
            verifierTokenContract.mint(msg.sender, 1);
            planterTokenContract.mint(ownerOf(_tokenId), 1);
        }
    }

    function removeVerification(uint256 _verificationId) public {
        // This function enables the owner of the NFT to remove verifications as he pleases (in case of fraudalent verification spam)

        TreeNftVerification memory treeNftVerification = s_tokenIDtoTreeNftVerfication[_verificationId];
        if (msg.sender != ownerOf(treeNftVerification.treeNftId)) revert NotTreeOwner();
        treeNftVerification.isHidden = true;
        User memory user = s_addressToUser[treeNftVerification.verifier];
        user.verificationsRevoked++;
        s_addressToUser[treeNftVerification.verifier] = user;
        emit VerificationRemoved(_verificationId, treeNftVerification.treeNftId, treeNftVerification.verifier);
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

    function getVerifiedTreesByUserPaginated(address verifier, uint256 offset, uint256 limit)
        public
        view
        returns (Tree[] memory trees, uint256 totalCount)
    {
        // Get the total number of trees verified by this verifier

        uint256[] memory verifiedTokens = s_verifierToTokenIDs[verifier];
        totalCount = verifiedTokens.length;
        if (offset >= totalCount) {
            return (new Tree[](0), totalCount);
        }
        uint256 end = offset + limit;
        if (end > totalCount) {
            end = totalCount;
        }
        uint256 resultLength = end - offset;
        trees = new Tree[](resultLength);
        for (uint256 i = 0; i < resultLength; i++) {
            uint256 tokenId = verifiedTokens[offset + i];
            trees[i] = s_tokenIDtoTree[tokenId];
        }

        return (trees, totalCount);
    }

    function getTreeNftVerifiers(uint256 _tokenId) public view returns (TreeNftVerification[] memory) {
        // This function retrieves all verifiers for a specific tree

        uint256[] storage verificationIds = s_treeTokenIdToVerifications[_tokenId];
        uint256 visibleCount;
        for (uint256 i = 0; i < verificationIds.length; i++) {
            if (!s_tokenIDtoTreeNftVerfication[verificationIds[i]].isHidden) {
                visibleCount++;
            }
        }
        TreeNftVerification[] memory treeNftVerifications = new TreeNftVerification[](visibleCount);
        uint256 currentIndex;
        for (uint256 i = 0; i < verificationIds.length; i++) {
            TreeNftVerification memory verification = s_tokenIDtoTreeNftVerfication[verificationIds[i]];
            if (!verification.isHidden) {
                treeNftVerifications[currentIndex] = verification;
                currentIndex++;
            }
        }
        return treeNftVerifications;
    }

    function getTreeNftVerifiersPaginated(uint256 _tokenId, uint256 offset, uint256 limit)
        public
        view
        returns (TreeNftVerification[] memory verifications, uint256 totalCount, uint256 visiblecount)
    {
        // This function retrieves all verifiers for a specific tree with pagination

        uint256[] storage verificationIds = s_treeTokenIdToVerifications[_tokenId];
        totalCount = verificationIds.length;
        uint256 visibleCount = 0;
        for (uint256 i = 0; i < totalCount; i++) {
            if (!s_tokenIDtoTreeNftVerfication[verificationIds[i]].isHidden) {
                visibleCount++;
            }
        }
        if (offset >= visibleCount) {
            return (new TreeNftVerification[](0), totalCount, visibleCount);
        }
        uint256 end = offset + limit;
        if (end > visibleCount) {
            end = visibleCount;
        }
        uint256 resultLength = end - offset;
        verifications = new TreeNftVerification[](resultLength);
        uint256 visibleIndex;
        uint256 resultIndex;
        for (uint256 i = 0; i < totalCount && resultIndex < resultLength; i++) {
            TreeNftVerification memory verification = s_tokenIDtoTreeNftVerfication[verificationIds[i]];
            if (!verification.isHidden) {
                if (visibleIndex >= offset && visibleIndex < end) {
                    verifications[resultIndex] = verification;
                    resultIndex++;
                }
                visibleIndex++;
            }
        }
        return (verifications, totalCount, visibleCount);
    }

    function markDead(uint256 tokenId) public {
        // This function marks a tree as dead

        if (!_exists(tokenId)) revert InvalidTreeID();
        if (s_tokenIDtoTree[tokenId].death != type(uint256).max) revert TreeAlreadyDead();
        if (ownerOf(tokenId) != msg.sender) revert NotTreeOwner();
        if (s_tokenIDtoTree[tokenId].planting + minimumTimeToMarkTreeDead >= block.timestamp) {
            revert MinimumMarkDeadTimeNotReached();
        }

        legacyToken.mint(msg.sender, 1);

        s_tokenIDtoTree[tokenId].death = block.timestamp;
        s_deathCounter++;
    }

    function registerUserProfile(string memory _name, string memory _profilePhotoHash) public {
        // This function registers a user

        if (s_addressToUser[msg.sender].userAddress != address(0)) revert UserAlreadyRegistered();
        User memory user = User(msg.sender, _profilePhotoHash, _name, block.timestamp, 0, 0);
        s_addressToUser[msg.sender] = user;
        s_userCounter++;
    }

    function updateUserDetails(string memory _name, string memory _profilePhotoHash) public {
        // This function enables a user to change his user details

        if (s_addressToUser[msg.sender].userAddress == address(0)) revert UserNotRegistered();
        s_addressToUser[msg.sender].name = _name;
        s_addressToUser[msg.sender].profilePhotoIpfs = _profilePhotoHash;
    }

    function isVerified(uint256 tokenId, address verifier) public view returns (bool) {
        // This function checks if a verifier has verified a tree

        return s_tokenIDtoUserVerification[tokenId][verifier];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < s_tokenCounter && tokenId >= 0;
    }
}
