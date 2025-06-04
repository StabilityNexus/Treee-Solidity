// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Organisation.sol";
import "./utils/structs.sol";
import "./utils/errors.sol";

contract OrganisationFactory is Ownable {
    uint256 private s_organisationCounter;
    address public treeNFTContract;

    mapping(uint256 => address) private s_organisationIdToAddress;
    mapping(address => uint256[]) public s_userToOrganisations;
    mapping(address => uint256) private s_organisationAddressToId;
    mapping(address => bool) private s_isOrganisation;

    address[] private s_allOrganisations;
    uint256[] private s_allOrganisationIds;

    constructor(address _treeNFTContract) Ownable(msg.sender) {
        s_organisationCounter = 0;
        treeNFTContract = _treeNFTContract;
    }

    function createOrganisation(string memory _name, string memory _description, string memory _photoIpfsHash)
        external
        returns (uint256 organisationId, address organisationAddress)
    {
        // This function allows a user to create a new organization.

        if (bytes(_name).length == 0) revert InvalidNameInput();
        if (bytes(_description).length == 0) revert InvalidDescriptionInput();
        organisationId = s_organisationCounter;

        // Deploy new Organization contract
        Organisation newOrganisation = new Organisation(
            organisationId, _name, _description, _photoIpfsHash, msg.sender, address(this), treeNFTContract, msg.sender
        );
        organisationAddress = address(newOrganisation);
        s_organisationIdToAddress[organisationId] = organisationAddress;
        s_organisationAddressToId[organisationAddress] = organisationId;
        s_userToOrganisations[msg.sender].push(organisationId);
        s_isOrganisation[organisationAddress] = true;
        s_allOrganisations.push(organisationAddress);
        s_allOrganisationIds.push(organisationId);
        s_organisationCounter++;
        return (organisationId, organisationAddress);
    }

    function getOrganisationAddress(uint256 _organizationId) external view returns (address) {
        // This function retrives the address of an organization based on its ID.

        if (_organizationId >= s_organisationCounter || _organizationId < 0) revert InvalidOrganisationId();
        if (s_organisationIdToAddress[_organizationId] == address(0)) revert OrganisationDoesNotExist();
        address orgAddress = s_organisationIdToAddress[_organizationId];
        return orgAddress;
    }

    function getUserOrganisations(address _user) external view returns (uint256[] memory) {
        // This function retrieves the list of organization IDs associated with a user.

        return s_userToOrganisations[_user];
    }

    function getMyOrganisations() external view returns (uint256[] memory) {
        // This function retrieves the list of organization IDs associated with the caller.

        return s_userToOrganisations[msg.sender];
    }

    function getAllOrganisations() external view returns (address[] memory) {
        // This function retrieves the list of all organization addresses.

        return s_allOrganisations;
    }

    function getAllOrganisationIds() external view returns (uint256[] memory) {
        // This function retrieves the list of all organization IDs.

        return s_allOrganisationIds;
    }

    function getOrganisationCount() external view returns (uint256) {
        // This function retrieves the total number of organisations created.

        return s_organisationCounter;
    }

    function addMemberToOrganisation(address _member) external {
        // This function adds a member to an organization.
        uint256 _organisationId = s_organisationAddressToId[msg.sender];
        if (!s_isOrganisation[msg.sender]) revert InvalidOrganisation();
        if (_organisationId >= s_organisationCounter || _organisationId < 0) revert InvalidOrganisationId();
        if (s_organisationIdToAddress[_organisationId] == address(0)) revert OrganisationDoesNotExist();
        s_userToOrganisations[_member].push(_organisationId);
    }

    function getOrganisationInfo(uint256 _organizationId)
        external
        view
        returns (
            address organizationAddress,
            uint256 id,
            string memory name,
            string memory description,
            string memory photoIpfsHash,
            address[] memory owners,
            address[] memory members,
            uint256 timeOfCreation
        )
    {
        // This function retrieves detailed information about an organization based on its ID.

        if (_organizationId >= s_organisationCounter || _organizationId < 0) revert InvalidOrganisationId();
        if (s_organisationIdToAddress[_organizationId] == address(0)) revert OrganisationDoesNotExist();
        organizationAddress = s_organisationIdToAddress[_organizationId];
        Organisation org = Organisation(organizationAddress);
        return org.getOrganisationInfo();
    }

    function getAllOrganisationDetails() external view returns (OrganisationDetails[] memory organizationDetails) {
        // This function retrieves detailed information about all organizations.

        uint256 totalOrgs = s_allOrganisations.length;
        organizationDetails = new OrganisationDetails[](totalOrgs);
        for (uint256 i = 0; i < totalOrgs; i++) {
            address organisationAddress = s_allOrganisations[i];
            Organisation org = Organisation(organisationAddress);
            try org.getOrganisationInfo() returns (
                address orgAddress,
                uint256 id,
                string memory name,
                string memory description,
                string memory photoIpfsHash,
                address[] memory owners,
                address[] memory members,
                uint256 timeOfCreation
            ) {
                organizationDetails[i] = OrganisationDetails({
                    id: id,
                    contractAddress: orgAddress,
                    name: name,
                    description: description,
                    photoIpfsHash: photoIpfsHash,
                    owners: owners,
                    members: members,
                    ownerCount: owners.length,
                    memberCount: members.length,
                    isActive: s_isOrganisation[orgAddress],
                    timeOfCreation: timeOfCreation
                });
            } catch {
                organizationDetails[i] = OrganisationDetails({
                    id: s_allOrganisationIds[i],
                    contractAddress: organisationAddress,
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
        // This function updates the address of the Tree NFT contract.

        if (_newTreeNFTContract == address(0)) revert InvalidInput();
        treeNFTContract = _newTreeNFTContract;
    }

    function removeOrganisation(address _organisationAddress) external onlyOwner {
        // This function allows the owner to remove an organization from the factory.

        if (s_isOrganisation[_organisationAddress] == false) revert OrganisationDoesNotExist();
        for (uint256 i = 0; i < s_allOrganisations.length; i++) {
            if (s_allOrganisations[i] == _organisationAddress) {
                s_allOrganisations[i] = s_allOrganisations[s_allOrganisations.length - 1];
                s_allOrganisations.pop();
                s_allOrganisationIds[i] = s_allOrganisationIds[s_allOrganisationIds.length - 1];
                s_allOrganisationIds.pop();
                break;
            }
        }
    }

    function getTreeNFTContract() external view returns (address) {
        // This function retrieves the address of the Tree NFT contract.
        return treeNFTContract;
    }

    function isValidOrganisation(address _organisationAddress) external view returns (bool) {
        // This function checks if the provided address is a valid organisation.

        return s_isOrganisation[_organisationAddress];
    }
}
