// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Organisation.sol";
import "./utils/structs.sol";
import "./utils/errors.sol";

contract OrganisationFactory is Ownable {
    uint256 private s_organizationCounter;
    address public treeNFTContract;
    
    mapping(uint256 => address) private s_organizationIdToAddress;
    mapping(address => uint256[]) public s_userToOrganizations;
    mapping(address => uint256) private s_organisationAddressToId;
    mapping(address => bool) private s_isOrganization;
    
    address[] private s_allOrganizations;
    uint256[] private s_allOrganizationIds;
    
    event OrganizationCreated(
        uint256 indexed organizationId,
        address indexed organizationAddress,
        address indexed creator,
        string name
    );
    
    event TreeNFTContractUpdated(
        address indexed oldContract,
        address indexed newContract
    );
    
    constructor(address _treeNFTContract) Ownable(msg.sender) {
        s_organizationCounter = 0;
        treeNFTContract = _treeNFTContract;
    }
    function createOrganization(
        string memory _name,
        string memory _description,
        string memory _photoIpfsHash
    ) external returns (uint256 organizationId, address organizationAddress) {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        organizationId = s_organizationCounter;
        
        // Deploy new Organization contract
        Organisation newOrganization = new Organisation(
            organizationId,
            _name,
            _description,
            _photoIpfsHash,
            msg.sender,
            address(this),
            treeNFTContract
        );
        
        organizationAddress = address(newOrganization);
        s_organizationIdToAddress[organizationId] = organizationAddress;
        s_organisationAddressToId[organizationAddress] = organizationId;
        s_userToOrganizations[msg.sender].push(organizationId);
        s_isOrganization[organizationAddress] = true;
        s_allOrganizations.push(organizationAddress);
        s_allOrganizationIds.push(organizationId);
        s_organizationCounter++;
        
        emit OrganizationCreated(organizationId, organizationAddress, msg.sender, _name);
        
        return (organizationId, organizationAddress);
    }
    function getOrganizationAddress(uint256 _organizationId) external view returns (address) {
        address orgAddress = s_organizationIdToAddress[_organizationId];
        require(orgAddress != address(0), "Organization does not exist");
        return orgAddress;
    }
    function getUserOrganizations(address _user) external view returns (uint256[] memory) {
        return s_userToOrganizations[_user];
    }

    function addUserToOrganization(address _user) external {
        require(s_isOrganization[msg.sender], "Only organization can add user");
        uint256 organisationId = s_organisationAddressToId[msg.sender];
        s_userToOrganizations[_user].push(organisationId);
    }

    function getMyOrganizations() external view returns (uint256[] memory) {
        return s_userToOrganizations[msg.sender];
    }

    function getAllOrganizations() external view returns (address[] memory) {
        return s_allOrganizations;
    }
    function getAllOrganizationIds() external view returns (uint256[] memory) {
        return s_allOrganizationIds;
    }

    function getOrganizationCount() external view returns (uint256) {
        return s_organizationCounter;
    }

    function isValidOrganization(address _organizationAddress) external view returns (bool) {
        return s_isOrganization[_organizationAddress];
    }

    function getOrganizationInfo(uint256 _organizationId) external view returns (
        address organizationAddress,
        uint256 id,
        string memory name,
        string memory description,
        string memory photoIpfsHash,
        address[] memory owners,
        address[] memory members,
        uint256 timeOfCreation
    ) {
        organizationAddress = s_organizationIdToAddress[_organizationId];
        require(organizationAddress != address(0), "Organization does not exist");
        
        Organisation org = Organisation(organizationAddress);
        return org.getOrganizationInfo();
    }
    function getAllOrganizationDetails() external view returns (OrganizationDetails[] memory organizationDetails) {
        uint256 totalOrgs = s_allOrganizations.length;
        organizationDetails = new OrganizationDetails[](totalOrgs);
        for (uint256 i = 0; i < totalOrgs; i++) {
            address orgAddress = s_allOrganizations[i];
            Organisation org = Organisation(orgAddress);
            try org.getOrganizationInfo() returns (
                address orgAddress,
                uint256 id,
                string memory name,
                string memory description,
                string memory photoIpfsHash,
                address[] memory owners,
                address[] memory members,
                uint256 timeOfCreation
            ) {
                organizationDetails[i] = OrganizationDetails({
                    id: id,
                    contractAddress: orgAddress,
                    name: name,
                    description: description,
                    photoIpfsHash: photoIpfsHash,
                    owners: owners,
                    members: members,
                    ownerCount: owners.length,
                    memberCount: members.length,
                    isActive: s_isOrganization[orgAddress],
                    timeOfCreation: timeOfCreation
                });
            } catch {
                organizationDetails[i] = OrganizationDetails({
                    id: s_allOrganizationIds[i],
                    contractAddress: orgAddress,
                    name: "ERROR: Unable to fetch",
                    description: "ERROR: Contract call failed",
                    photoIpfsHash: "",
                    owners: new address[](0),
                    members: new address[](0),
                    ownerCount: 0,
                    memberCount: 0,
                    isActive: false,
                    timeOfCreation: 0
                });
            }
        }
        
        return organizationDetails;
    }

    function updateTreeNFTContract(address _newTreeNFTContract) external onlyOwner {
        require(_newTreeNFTContract != address(0), "Invalid contract address");
        
        address oldContract = treeNFTContract;
        treeNFTContract = _newTreeNFTContract;
        
        emit TreeNFTContractUpdated(oldContract, _newTreeNFTContract);
    }

    function removeOrganization(address _organizationAddress) external onlyOwner {
        require(s_isOrganization[_organizationAddress], "Not a valid organization");
        s_isOrganization[_organizationAddress] = false;
        for (uint256 i = 0; i < s_allOrganizations.length; i++) {
            if (s_allOrganizations[i] == _organizationAddress) {
                s_allOrganizations[i] = s_allOrganizations[s_allOrganizations.length - 1];
                s_allOrganizations.pop();
                s_allOrganizationIds[i] = s_allOrganizationIds[s_allOrganizationIds.length - 1];
                s_allOrganizationIds.pop();
                break;
            }
        }
    }
    
    function getTreeNFTContract() external view returns (address) {
        return treeNFTContract;
    }
}