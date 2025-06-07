// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct OrganisationDetails {
    address contractAddress;
    string name;
    string description;
    string photoIpfsHash;
    address[] owners;
    address[] members;
    uint256 ownerCount;
    uint256 memberCount;
    bool isActive;
    uint256 timeOfCreation;
}

struct TreeNftVerification {
    address verifier;
    uint256 timestamp;
    string[] proofHashes;
    string description;
    bool isHidden;
    uint256 treeNftId;
}

struct OrganisationVerificationRequest {
    uint256 id;
    address initialMember;
    address organisationContract;
    uint256 status;
    string description;
    uint256 timestamp;
    string[] proofHashes;
    uint256 treeNftId;
}

struct User {
    address userAddress;
    string profilePhotoIpfs;
    string name;
    uint256 dateJoined;
    uint256 verificationsRevoked;
    uint256 reportedSpam;
}

struct Tree {
    uint256 latitude;
    uint256 longitude;
    uint256 planting;
    uint256 death;
    string species;
    string imageUri;
    string qrIpfsHash;
    string[] photos;
    string geoHash;
    address[] ancestors;
    uint256 lastCareTimestamp;
    uint256 careCount;
}

struct TreePlantingProposal {
    uint256 id;
    uint256 latitude;
    uint256 longitude;
    string species;
    string imageUri;
    string qrIpfsHash;
    string[] photos;
    string geoHash;
    uint256 status;
}
