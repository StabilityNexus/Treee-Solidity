// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./utils/structs.sol";
import "./utils/errors.sol";
import "./TreeNft.sol";
import "./OrganisationFactory.sol";

contract Organisation {
    uint256 public immutable id;
    string public name;
    string public description;
    string public photoIpfsHash;
    address public organisationFactoryAddress;
    address[] public owners;
    address[] public members;
    uint256 public timeOfCreation;
    address public founder;

    TreeNft public treeNFTContract;

    uint256 private s_verificationCounter;
    uint256 private s_leftMembersCounter;

    mapping(uint256 => OrganisationVerificationRequest) private s_verificationIDtoVerification;
    mapping(address => OrganisationVerificationRequest[]) private s_userAddressToVerifications;
    mapping(uint256 => address[]) private s_verificationYesVoters;
    mapping(uint256 => address[]) private s_verificationNoVoters;

    event UserAddedToOrganisation(
        address indexed user, address indexed organisationContract, uint256 timestamp, address by_user
    );

    event UserRemovedFromOrganisation(
        address indexed user, address indexed organisationContract, uint256 timestamp, address by_user
    );

    modifier onlyOwner() {
        if (!checkOwnership(msg.sender)) revert OnlyOwner();
        _;
    }

    constructor(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _photoIpfsHash,
        address _creator,
        address _factoryAddress,
        address _treeNFTContractAddress,
        address _founder
    ) {
        require(_creator != address(0), "Invalid creator address");
        require(_factoryAddress != address(0), "Invalid factory address");
        require(_treeNFTContractAddress != address(0), "Invalid tree NFT address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        id = _id;
        name = _name;
        description = _description;
        photoIpfsHash = _photoIpfsHash;
        organisationFactoryAddress = _factoryAddress;
        founder = _founder;
        owners.push(_creator);
        members.push(_creator);
        s_leftMembersCounter = 0;
        s_verificationCounter = 0;
        timeOfCreation = block.timestamp;
        treeNFTContract = TreeNft(_treeNFTContractAddress);
    }

    function addMember(address user) external onlyOwner {
        // This function is called by an owner to process a join request

        require(user != address(0), "Invalid address");
        require(!checkMembership(user), "Already a member");
        members.push(user);
        emit UserAddedToOrganisation(user, address(this), block.timestamp, msg.sender);
    }

    function leaveOrganisation() external {
        // This function allows a user to leave the organisation

        require(checkMembership(msg.sender), "Not a member");
        uint256 ownerCount = owners.length;
        if (ownerCount == 1 && owners[0] == msg.sender) {
            revert NeedAnotherOwner();
        }
        bool found = false;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                found = true;
                break;
            }
        }
        require(found, "User is not a member");
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        emit UserRemovedFromOrganisation(msg.sender, address(this), block.timestamp, msg.sender);
    }

    function removeMember(address member) external onlyOwner {
        // This function allows an owner to remove a member from the organisation

        require(checkMembership(member), "Not a member");
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == member) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        emit UserRemovedFromOrganisation(member, address(this), block.timestamp, msg.sender);
    }

    function requestVerification(string memory _description, string[] memory _proofHashes, uint256 _treeNftID)
        external
        returns (uint256)
    {
        // This function allows a user to request verification of a tree

        require(checkMembership(msg.sender), "Not a member!");
        OrganisationVerificationRequest memory request = OrganisationVerificationRequest({
            id: s_verificationCounter,
            initialMember: msg.sender,
            organisationContract: address(this),
            status: 0,
            description: _description,
            timestamp: block.timestamp,
            proofHashes: _proofHashes,
            treeNftId: _treeNftID
        });
        if (checkOwnership(msg.sender)) {
            s_verificationYesVoters[s_verificationCounter].push(msg.sender);
        }
        s_verificationIDtoVerification[s_verificationCounter] = request;
        s_userAddressToVerifications[msg.sender].push(request);
        s_verificationCounter++;
        return request.id;
    }

    function getVerificationRequest(uint256 verificationID)
        external
        view
        returns (OrganisationVerificationRequest memory)
    {
        // This function returns a specific verification request by its ID

        require(verificationID < s_verificationCounter, "Invalid verification ID");
        return s_verificationIDtoVerification[verificationID];
    }

    function getVerificationRequests() external view returns (OrganisationVerificationRequest[] memory) {
        // This function returns all verification requests for the organisation

        OrganisationVerificationRequest[] memory requests = new OrganisationVerificationRequest[](s_verificationCounter);
        for (uint256 i = 0; i < s_verificationCounter; i++) {
            requests[i] = s_verificationIDtoVerification[i];
        }
        return requests;
    }

    function voteOnVerificationRequest(uint256 verificationID, uint256 vote) external onlyOwner {
        // This function allows an owner to vote on a verification request

        OrganisationVerificationRequest storage request = s_verificationIDtoVerification[verificationID];
        require(request.status == 0, "Request already processed");
        require(request.initialMember != msg.sender, "You cannot vote on your own request");
        if (vote == 1) {
            s_verificationYesVoters[verificationID].push(msg.sender);
        } else {
            s_verificationNoVoters[verificationID].push(msg.sender);
        }

        if (
            s_verificationYesVoters[verificationID].length == owners.length / 2
                || s_verificationYesVoters[verificationID].length > owners.length / 2
        ) {
            request.status = 1;
            treeNFTContract.verify(request.treeNftId);
        } else if (s_verificationNoVoters[verificationID].length == owners.length / 2) {
            request.status = 2;
        }
    }

    function makeOwner(address newOwner) external onlyOwner {
        // This function allows an owner to add a new owner to the organisation
        require(newOwner != address(0), "Invalid address");
        require(checkMembership(newOwner), "Must be a member first");
        require(!checkOwnership(newOwner), "Already an owner");
        owners.push(newOwner);
    }

    function checkOwnership(address user) public view returns (bool) {
        // This function checks if the specified user is an owner of the organisation

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == user) {
                return true;
            }
        }
        return false;
    }

    function checkMembership(address user) public view returns (bool) {
        // This function checks if the specified user is a member of the organisation

        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getMembers() external view returns (address[] memory) {
        // This function returns the list of members in the organisation

        return members;
    }

    function getOwners() external view returns (address[] memory) {
        // This function returns the list of owners in the organisation

        return owners;
    }

    function getMemberCount() external view returns (uint256) {
        // This function returns the count of members in the organisation

        return members.length;
    }

    function getOrganisationInfo()
        external
        view
        returns (
            address,
            uint256,
            string memory,
            string memory,
            string memory,
            address[] memory,
            address[] memory,
            uint256
        )
    {
        // This function returns detailed information about the organisation

        return (address(this), id, name, description, photoIpfsHash, owners, members, timeOfCreation);
    }
}
