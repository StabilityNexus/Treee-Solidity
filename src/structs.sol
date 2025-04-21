// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct Organisation {
    uint256 id;
    string name;
    string description;
    address[] owners;
    JoinRequest[] requests;
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
    address user;
    uint256 status;  // 0 = pending, 1 = approved, 2 = denied
    string description;
    uint256 timestamp;
}

struct User {
    address userAddress;
    string profilePhotoIpfs;
    string name;
    uint256 dateJoined;
}