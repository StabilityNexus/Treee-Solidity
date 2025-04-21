// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./structs.sol";
import "./errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserActivityContract is Ownable {
    uint256 private s_organisationCounter;
    uint256 private s_requestCounter;
    mapping(uint256 => Organisation) private s_organisationIDtoOrganisation;
    mapping(uint256 => JoinRequest) private s_requestIDtoJoinRequest;
    mapping(address => uint256[]) private s_userToOrganisations;
    mapping(uint256 => JoinRequest[]) private s_organisationToJoinRequests;
    mapping(address => User) private s_addressToUser;
    constructor() Ownable(msg.sender) {
        s_organisationCounter = 0;
        s_requestCounter = 0;
    }
    function createOrganisation(string memory name, string memory description, string memory photoIpfsHash) public returns (uint256) {
        if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(""))) {
            revert InvalidNameInput();
        }
        if(keccak256(abi.encodePacked(description)) == keccak256(abi.encodePacked(""))) {
            revert InvalidDescriptionInput();
        }
        uint256 organisationId = s_organisationCounter;
        Organisation storage newOrganisation = s_organisationIDtoOrganisation[organisationId];
        newOrganisation.id = organisationId;
        newOrganisation.name = name;
        newOrganisation.description = description;
        newOrganisation.photoIpfsHash = photoIpfsHash;
        newOrganisation.owners.push(msg.sender); 
        newOrganisation.members.push(msg.sender);
        s_userToOrganisations[msg.sender].push(organisationId);
        s_organisationCounter++;
        return newOrganisation.id;
    }

    function getOrganisation(uint256 organisationId) public view returns (Organisation memory) {
        if (organisationId == type(uint256).max || organisationId < 0) {
            return Organisation({
                id: type(uint256).max, 
                name: "",
                description: "",
                owners: new address[](0), 
                members: new address[](0), 
                photoIpfsHash: "",
                timestamps: new uint256[](0) 
            });
        }
        require(organisationId < s_organisationCounter, "Organisation does not exist");
        return s_organisationIDtoOrganisation[organisationId];
    }
    
    function getUserOrganisations(address user) public view returns (uint256[] memory) {
        return s_userToOrganisations[user];
    }
    
    function requestToJoinOrganisation(uint256 organisationId, string memory description) public {
        require(organisationId < s_organisationCounter, "Organisation does not exist");
        Organisation storage org = s_organisationIDtoOrganisation[organisationId];

        if (checkMembership(msg.sender, organisationId)) {
            revert AlreadyVerified();
        }

        JoinRequest memory request = JoinRequest({
            id: s_requestCounter,
            user: msg.sender,
            organisation: org,
            status: 0,
            description: description,
            timestamp: block.timestamp,
            reviewer: User(address(0), "", "", 0)
        });

        s_organisationToJoinRequests[organisationId].push(request);
        s_requestIDtoJoinRequest[s_requestCounter] = request;
        s_requestCounter++;
    }


    function getOrganisationJoinRequests(uint256 organisationId) public view returns (JoinRequest[] memory) {
        if(organisationId >= s_organisationCounter || organisationId < 0) {
            revert InvalidOrganisationIdInput();
        }
        if (checkOwnership(msg.sender, organisationId) == false) {
            revert NotOrganisationOwner();
        }
        return s_organisationToJoinRequests[organisationId];
    }

    function processJoinRequest(uint256 requestID, uint256 status) public {
        require(status == 1 || status == 2, "Invalid status"); // 1 = approved, 2 = denied

        JoinRequest storage request = s_requestIDtoJoinRequest[requestID];
        uint256 organisationId = request.organisation.id;

        require(organisationId < s_organisationCounter, "Organisation does not exist");
        require(request.status == 0, "Request already processed");

        if (!checkOwnership(msg.sender, organisationId)) {
            revert NotOrganisationOwner();
        }
        request.status = status;
        if (status == 1) {
            Organisation storage org = s_organisationIDtoOrganisation[organisationId];
            org.members.push(request.user); 
            s_userToOrganisations[request.user].push(organisationId);
        }
        else {
            request.status = 2; // Denied
        }
        request.reviewer = s_addressToUser[msg.sender];
    }


    function leaveOrganisation(uint256 organisationId) public {
        require(organisationId < s_organisationCounter, "Organisation does not exist");
        Organisation storage org = s_organisationIDtoOrganisation[organisationId];
        uint256 orgOwnersCount = org.owners.length;
        if(orgOwnersCount == 1 && org.owners[0] == msg.sender) {
            revert NeedAnotherOwner();
        }
        bool found = false;
        for (uint i = 0; i < org.members.length; i++) {
            if (org.members[i] == msg.sender) {
                // Replace with last member and remove last element
                org.members[i] = org.members[org.members.length - 1];
                org.members.pop();
                found = true;
                break;
            }
        }
        require(found, "User is not a member of this organisation");
        uint256[] storage userOrgs = s_userToOrganisations[msg.sender];
        for (uint i = 0; i < userOrgs.length; i++) {
            if (userOrgs[i] == organisationId) {
                userOrgs[i] = userOrgs[userOrgs.length - 1];
                userOrgs.pop();
                break;
            }
        }
    }

    function makeOrganisationOwner(uint256 organisationId, address newOwner) public {
        require(organisationId < s_organisationCounter, "Organisation does not exist");
        Organisation storage org = s_organisationIDtoOrganisation[organisationId];
        require(checkMembership(newOwner, organisationId), "New owner must be a member of the organisation");
        org.owners.push(newOwner);
    }

    function removeMember(uint256 organisationId, address member) public {
        require(organisationId < s_organisationCounter, "Organisation does not exist");
        if(checkOwnership(msg.sender, organisationId) == false) {
            revert NotOrganisationOwner();
        }
        if(checkMembership(member, organisationId) == false) {
            revert NotOrganisationMember();
        }
        uint256[] storage userOrgs = s_userToOrganisations[member];
        for (uint i = 0; i < userOrgs.length; i++) {
            if (userOrgs[i] == organisationId) {
                userOrgs[i] = userOrgs[userOrgs.length - 1];
                userOrgs.pop();
                break;
            }
        }
    }
    function getOrganisationCount() public view returns (uint256) {
        return s_organisationCounter;
    }


    function checkOwnership(address user, uint256 organisationId) public view returns (bool) {
        Organisation storage org = s_organisationIDtoOrganisation[organisationId];
        for (uint i = 0; i < org.owners.length; i++) {
            if (org.owners[i] == user) {
                return true;
            }
        }
        return false;
    }
    function checkMembership(address user, uint256 organisationId) public view returns (bool) {
        if(organisationId == type(uint256).max) {
            return true;
        }
        uint256 [] storage userOrgs = s_userToOrganisations[user];
        for (uint i = 0; i < userOrgs.length; i++) {
            if (userOrgs[i] == organisationId) {
                return true;
            }
        }
        return false;
    }
    
    function updateUserProfilePhoto(string memory _profilePhotoIpfs) public {
        User storage user = s_addressToUser[msg.sender];
        user.userAddress = msg.sender;
        if(user.userAddress == address(0)) {
            revert("User does not exist");
        }
        if (keccak256(abi.encodePacked(_profilePhotoIpfs)) != keccak256(abi.encodePacked(""))) {
            user.profilePhotoIpfs = _profilePhotoIpfs;
        }
        user.dateJoined = user.dateJoined == 0 ? block.timestamp : user.dateJoined;
    }

    function updateUsername(string memory _name) public {
        User storage user = s_addressToUser[msg.sender];
        if(user.userAddress == address(0)) {
            revert("User does not exist");
        }
        user.userAddress = msg.sender;
        if (keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(""))) {
            user.name = _name;
        }
    }

    function getUserProfile(address userAddress) public view returns (User memory) {
        return s_addressToUser[userAddress];
    }
    function initialiseUserProfile(string memory _profilePhotoIpfs, string memory _name) public {
        require(
            s_addressToUser[msg.sender].userAddress == address(0), 
            "Profile already exists"
        );
        if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(""))) revert InvalidNameInput();
        User storage user = s_addressToUser[msg.sender];
        user.userAddress = msg.sender;
        user.profilePhotoIpfs = _profilePhotoIpfs;
        user.name = _name;
        user.dateJoined = block.timestamp;
    }
    
}
