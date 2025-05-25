// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct OrganisationDetails {
    uint256 id;
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

struct Verification {
    address verifier;
    uint256 timestamp;
    string[] proofHashes;
    string description;
}

struct OrganisationVerificationRequest {
    uint256 id;
    address initial_member;
    address organisationContract;
    uint256 status;
    string description;
    uint256 timestamp;
    string[] proofHashes;
    uint256 treeNFTID;
}

struct JoinRequest {
    uint256 id;
    address user;
    address organisationContract;
    uint256 status; // 0 = pending, 1 = approved, 2 = denied
    string description;
    uint256 timestamp;
    address reviewer;
}

struct User {
    address userAddress;
    string profilePhotoIpfs;
    string name;
    uint256 dateJoined;
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
    address organisationAddress;
    Verification[] verifiers;
    uint256 lastCareTimestamp;
    uint256 careCount;
}
