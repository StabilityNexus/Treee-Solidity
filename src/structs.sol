// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct Organisation {
    uint256 id;
    string name;
    string description;
    address[] owners;
    address [] members;
    string photoIpfsHash;
    uint256[] timestamps;
}

struct Verification {
    address verifier;
    uint256 timestamp;
    string[] proofHashes;
    string description;
}

struct JoinRequest{
    uint256 id;
    address user;
    Organisation organisation;
    uint256 status;  // 0 = pending, 1 = approved, 2 = denied
    string description;
    uint256 timestamp;
    User reviewer;
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
    string imageUri; // Added field for image URI
    string qrIpfsHash;
    string[] photos; 
    string geoHash;
    address[] ancestors;
    Organisation organisation;
    Verification [] verifiers;
 }