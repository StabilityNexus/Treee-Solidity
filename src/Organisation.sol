// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/structs.sol";
import "./utils/errors.sol";
import "./TreeeNft.sol";
import "./OrganisationFactory.sol";

contract Organisation is Ownable{
    uint256 public immutable id;
    address public immutable organisationContract;
    address public treeNFTContract;
    string public name;
    string public description;
    string public photoIpfsHash;
    address public organisationFactoryAddress;
    address[] public owners;
    address[] public members;
    uint256 public timeOfCreation;
    JoinRequest[] private s_joinRequests;
    TreeNft private s_treeNFTContract;
    
    uint256 private s_requestCounter;
    uint256 private s_verificationCounter;
    uint256 private s_leftMembersCounter;

    mapping(uint256 => JoinRequest) private s_requestIDtoJoinRequest;
    mapping(address => address) private s_removedUsertoUser;
    mapping(uint256 => address) private s_leftMembers;


    mapping(address => User) private s_addressToUser;
    mapping(uint256 => OrganisationVerificationRequest) private s_verificationIDtoVerification;
    mapping(address => OrganisationVerificationRequest[]) private s_userAddressToVerifications;

    mapping(uint256 => address[]) private s_verificationYesVoters; 
    mapping(uint256 => address[]) private s_verificationNoVoters;

    mapping(address => uint256) private s_userToJoinTime;
    mapping(address => uint256) private s_userToLeaveTime;
    
    modifier onlyOwner override {
        require(checkOwnership(msg.sender), "Not an owner");
        _;
    }

    constructor(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _photoIpfsHash,
        address _creator,
        address _factoryAddress,
        address _treeNFTContractAddress

    ) Ownable(_factoryAddress) {
        id = _id;
        name = _name;
        description = _description;
        photoIpfsHash = _photoIpfsHash;
        organisationContract = address(this);
        organisationFactoryAddress = _factoryAddress;
        owners.push(_creator);
        members.push(_creator);
        s_requestCounter = 0;
        s_leftMembersCounter = 0;
        s_verificationCounter = 0;
        timeOfCreation = block.timestamp;
        treeNFTContract = _treeNFTContractAddress;
        s_treeNFTContract = TreeNft(_treeNFTContractAddress);
    }
    
    function requestToJoin(string memory _description, address _user) external onlyOwner {
        
        if (checkMembership(_user)) {
            revert AlreadyVerified();
        }
        
        JoinRequest memory request = JoinRequest({
            id: s_requestCounter,
            user: msg.sender,
            status: 0,
            description: _description,
            timestamp: block.timestamp,
            reviewer: _user, 
            organisationContract: address(this)
        });
        
        s_joinRequests.push(request);
        s_requestIDtoJoinRequest[s_requestCounter] = request;
        s_requestCounter++;
    }
    
    function getJoinRequests() external view onlyOwner returns (JoinRequest[] memory){
        require(checkOwnership(msg.sender), "Not an owner");
        return s_joinRequests;
    }
    
    function processJoinRequest(uint256 requestID, uint256 status) external onlyOwner {
        require(status == 1 || status == 2, "Invalid status"); 
        
        JoinRequest storage request = s_requestIDtoJoinRequest[requestID];
        require(request.status == 0, "Request already processed");
        request.status = status;
        request.reviewer = msg.sender;

        if (status == 1) {
            members.push(request.user);
            s_userToJoinTime[request.user] = block.timestamp;
            if(s_userToLeaveTime[request.user] != 0){
                s_userToLeaveTime[request.user] = 0;
            }
            OrganisationFactory(organisationFactoryAddress).addUserToOrganization(request.user);
        }
    }
    
    function leaveOrganization() external {
        require(checkMembership(msg.sender), "Not a member");
        
        uint256 ownerCount = owners.length;
        if (ownerCount == 1 && owners[0] == msg.sender) {
            revert NeedAnotherOwner();
        }
        
        bool found = false;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                members[i] = members[members.length - 1];
                members.pop();
                found = true;
                break;
            }
        }
        require(found, "User is not a member");
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        s_leftMembers[s_leftMembersCounter] = msg.sender;
        s_leftMembersCounter++;
        s_userToLeaveTime[msg.sender] = block.timestamp;
    }

    function removeMember(address member) external onlyOwner {
        require(checkMembership(member), "Not a member");
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == member) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        s_removedUsertoUser[member] = msg.sender;
        s_userToLeaveTime[member] = block.timestamp;
    }

    function getUserWhoRemoved(address user) external view returns (address, uint256) {
        require(!checkMembership(user), "Still a member!");
        return (s_removedUsertoUser[user], s_userToLeaveTime[user]);
    }

    function getUserJoinTime(address user) external view returns (uint256) {
        require(checkMembership(user), "Not a member!");
        return s_userToJoinTime[user];
    }

    function getUserLeaveTime(address user) external view returns (uint256) {
        require(!checkMembership(user), "Still a member!");
        return s_userToLeaveTime[user];
    }

    function requestVerification(string memory _description, string[] memory _proofHashes) external {
        require(checkMembership(msg.sender), "Not a member!");
        
        OrganisationVerificationRequest memory request = OrganisationVerificationRequest({
            id: s_verificationCounter,
            initial_member: msg.sender,
            organisationContract: address(this),
            status: 0,
            description: _description,
            timestamp: block.timestamp
        });
        if(checkOwnership(msg.sender)){
            s_verificationYesVoters[s_verificationCounter].push(msg.sender);
        }
        
        s_verificationIDtoVerification[s_verificationCounter] = request;
        s_userAddressToVerifications[msg.sender].push(request);
        s_verificationCounter++;
    }

    function voteOnVerificationRequest(uint256 verificationID, uint256 vote, uint256 treeTokenId) external onlyOwner {
        require(vote == 1 || vote == 2, "Invalid vote");
        OrganisationVerificationRequest storage request = s_verificationIDtoVerification[verificationID];
        require(request.status == 0, "Request already processed");
        require(request.initial_member != msg.sender, "You cannot vote on your own request");
        
        if (vote == 1) {
            s_verificationYesVoters[verificationID].push(msg.sender);
        } else {
            s_verificationNoVoters[verificationID].push(msg.sender);
        }

        if (s_verificationYesVoters[verificationID].length == owners.length / 2 || s_verificationYesVoters[verificationID].length > owners.length / 2) {
            request.status = 1; 
            s_treeNFTContract.verify(treeTokenId);
        } else if (s_verificationNoVoters[verificationID].length == owners.length / 2) {
            request.status = 2; 
        }
    }
    
    function makeOwner(address newOwner) external onlyOwner {
        owners.push(newOwner);
    }
    
    function checkOwnership(address user) public view  returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function checkMembership(address user) public view returns (bool) {
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getOwners() external view returns (address[] memory) {
        return owners;
    }
    
    function getMemberCount() external view  returns (uint256) {
        return members.length;
    }
    
    function getOrganizationInfo() external view  returns (
        address,
        uint256,
        string memory,
        string memory,
        string memory,
        address[] memory,
        address[] memory,
        uint256
    ) {
        return (address(this),id, name, description, photoIpfsHash, owners, members, timeOfCreation);
    }
}