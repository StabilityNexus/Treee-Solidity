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
    uint256 public paginationLimit;
    OrganisationFactory public organisationFactoryContract;
    address[] public owners;
    address[] public members;
    uint256 public timeOfCreation;
    address public founder;
    TreeNft public treeNFTContract;

    uint256 private s_verificationCounter;
    uint256 private s_treePlantingProposalCounter;

    mapping(uint256 => OrganisationVerificationRequest) private s_verificationIDtoVerification;
    mapping(address => OrganisationVerificationRequest[]) private s_userAddressToVerifications;
    mapping(uint256 => address[]) private s_verificationYesVoters;
    mapping(uint256 => address[]) private s_verificationNoVoters;

    mapping(uint256 => TreePlantingProposal) private s_treePlantingProposalIDtoTreePlantingProposal;
    mapping(address => TreePlantingProposal[]) private s_userAddressToTreePlantingProposals;
    mapping(uint256 => address[]) private s_treeProposalYesVoters;
    mapping(uint256 => address[]) private s_treeProposalNoVoters;

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
        if (_creator == address(0)) revert InvalidAddressInput();
        if (_factoryAddress == address(0)) revert InvalidAddressInput();
        if (_treeNFTContractAddress == address(0)) revert InvalidAddressInput();
        if (bytes(_name).length == 0) revert InvalidNameInput();
        id = _id;
        name = _name;
        description = _description;
        photoIpfsHash = _photoIpfsHash;
        founder = _founder;
        owners.push(_creator);
        members.push(_creator);
        s_treePlantingProposalCounter = 0;
        s_verificationCounter = 0;
        timeOfCreation = block.timestamp;
        treeNFTContract = TreeNft(_treeNFTContractAddress);
        organisationFactoryContract = OrganisationFactory(_factoryAddress);
        paginationLimit = 100;
    }

    function addMember(address user) external onlyOwner {
        // This function is called by an owner to process a join request

        if (user == address(0)) revert InvalidAddressInput();
        if (checkMembership(user)) revert AlreadyMember();
        members.push(user);
        organisationFactoryContract.addMemberToOrganisation(user);
        emit UserAddedToOrganisation(user, address(this), block.timestamp, msg.sender);
    }

    function leaveOrganisation() external {
        // This function allows a user to leave the organisation

        if (!checkMembership(msg.sender)) revert NotOrganisationMember();
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
        if (!found) revert NotOrganisationMember();
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

        if (!checkMembership(msg.sender)) revert NotOrganisationMember();
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
        if (!checkMembership(msg.sender)) revert NotOrganisationMember();

        OrganisationVerificationRequest memory request = OrganisationVerificationRequest({
            id: s_verificationCounter, // ID is current counter value
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
            if (owners.length <= 2) {
                request.status = 1;
                treeNFTContract.verify(request.treeNftId, request.proofHashes, request.description);
            }
        }
        s_userAddressToVerifications[msg.sender].push(request);
        s_verificationIDtoVerification[s_verificationCounter] = request;
        uint256 currentId = s_verificationCounter;
        s_verificationCounter++;
        return currentId;
    }

    function getVerificationRequest(uint256 verificationID)
        external
        view
        returns (OrganisationVerificationRequest memory)
    {
        // This function returns a specific verification request by its ID

        if (verificationID >= s_verificationCounter && verificationID < 0) revert InvalidVerificationId();
        return s_verificationIDtoVerification[verificationID];
    }

    function getVerificationRequests(uint256 status) external view returns (OrganisationVerificationRequest[] memory) {
        // First pass: count matching requests
        uint256 matchCount = 0;
        for (uint256 i = 0; i < s_verificationCounter; i++) {
            if (s_verificationIDtoVerification[i].status == status) {
                matchCount++;
            }
        }
        OrganisationVerificationRequest[] memory requests = new OrganisationVerificationRequest[](matchCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < s_verificationCounter; i++) {
            if (s_verificationIDtoVerification[i].status == status) {
                requests[currentIndex] = s_verificationIDtoVerification[i];
                currentIndex++;
            }
        }
        return requests;
    }

    function getVerificationRequestsByStatus(uint256 status, uint256 offset, uint256 limit)
        external
        view
        returns (OrganisationVerificationRequest[] memory requests, uint256 totalMatching, bool hasMore)
    {
        if (limit <= 0) revert InvalidInput();
        if (limit > paginationLimit) revert PaginationLimitExceeded();

        uint256 matchCount = 0;
        for (uint256 i = 0; i < s_verificationCounter; i++) {
            if (s_verificationIDtoVerification[i].status == status) {
                matchCount++;
            }
        }
        totalMatching = matchCount;
        if (offset >= matchCount) {
            return (new OrganisationVerificationRequest[](0), totalMatching, false);
        }
        uint256 remaining = matchCount - offset;
        uint256 itemsToReturn = remaining < limit ? remaining : limit;

        requests = new OrganisationVerificationRequest[](itemsToReturn);

        uint256 currentMatch = 0;
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < s_verificationCounter && resultIndex < itemsToReturn; i++) {
            if (s_verificationIDtoVerification[i].status == status) {
                if (currentMatch >= offset) {
                    requests[resultIndex] = s_verificationIDtoVerification[i];
                    resultIndex++;
                }
                currentMatch++;
            }
        }

        hasMore = offset + itemsToReturn < totalMatching;
        return (requests, totalMatching, hasMore);
    }

    function voteOnVerificationRequest(uint256 verificationID, uint256 vote) external onlyOwner {
        // This function allows an owner to vote on a verification request

        OrganisationVerificationRequest storage request = s_verificationIDtoVerification[verificationID];
        if (request.status != 0) revert AlreadyProcessed();
        if (vote == 1) {
            s_verificationYesVoters[verificationID].push(msg.sender);
        } else {
            s_verificationNoVoters[verificationID].push(msg.sender);
        }

        uint256 requiredVotes = (owners.length + 1) / 2;
        if (s_verificationYesVoters[verificationID].length >= requiredVotes) {
            request.status = 1;
            treeNFTContract.verify(request.treeNftId, request.proofHashes, request.description);
        } else if (s_verificationNoVoters[verificationID].length >= (owners.length - requiredVotes)) {
            request.status = 2;
        }
    }

    function plantTreeProposal(
        uint256 _latitude,
        uint256 _longitude,
        string memory _species,
        string memory _imageURI,
        string memory _qrIpfshash,
        string[] memory photos,
        string memory geoHash
    ) public {
        if (!checkMembership(msg.sender)) revert NotOrganisationMember();
        TreePlantingProposal memory proposal = TreePlantingProposal({
            id: s_treePlantingProposalCounter,
            latitude: _latitude,
            longitude: _longitude,
            species: _species,
            imageUri: _imageURI,
            qrIpfsHash: _qrIpfshash,
            photos: photos,
            geoHash: geoHash,
            status: 0
        });
        if (checkOwnership(msg.sender)) {
            s_treeProposalYesVoters[s_treePlantingProposalCounter].push(msg.sender);
            if (owners.length <= 2) {
                proposal.status = 1;
                treeNFTContract.mintNft(
                    proposal.latitude,
                    proposal.longitude,
                    proposal.species,
                    proposal.imageUri,
                    proposal.qrIpfsHash,
                    proposal.geoHash,
                    proposal.photos
                );
            }
        }
        s_userAddressToTreePlantingProposals[msg.sender].push(proposal);
        s_treePlantingProposalCounter++;
        s_treePlantingProposalIDtoTreePlantingProposal[proposal.id] = proposal;
    }

    function getTreePlantingProposal(uint256 proposalID) external view returns (TreePlantingProposal memory) {
        if (proposalID >= s_treePlantingProposalCounter) revert InvalidProposalId();
        return s_treePlantingProposalIDtoTreePlantingProposal[proposalID];
    }

    function getTreePlantingProposals(uint256 status) external view returns (TreePlantingProposal[] memory) {
        uint256 matchCount = 0;
        for (uint256 i = 0; i < s_treePlantingProposalCounter; i++) {
            if (s_treePlantingProposalIDtoTreePlantingProposal[i].status == status) {
                matchCount++;
            }
        }
        TreePlantingProposal[] memory proposals = new TreePlantingProposal[](matchCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < s_treePlantingProposalCounter; i++) {
            if (s_treePlantingProposalIDtoTreePlantingProposal[i].status == status) {
                proposals[currentIndex] = s_treePlantingProposalIDtoTreePlantingProposal[i];
                currentIndex++;
            }
        }

        return proposals;
    }

    function getTreePlantingProposalsByStatus(uint256 status, uint256 offset, uint256 limit)
        external
        view
        returns (TreePlantingProposal[] memory proposals, uint256 totalMatching, bool hasMore)
    {
        if (limit <= 0) revert InvalidInput();
        if (limit > paginationLimit) revert PaginationLimitExceeded();

        // First pass: count total matching proposals
        uint256 matchCount = 0;
        for (uint256 i = 0; i < s_treePlantingProposalCounter; i++) {
            if (s_treePlantingProposalIDtoTreePlantingProposal[i].status == status) {
                matchCount++;
            }
        }

        totalMatching = matchCount;
        if (offset >= matchCount) {
            return (new TreePlantingProposal[](0), totalMatching, false);
        }

        uint256 remaining = matchCount - offset;
        uint256 itemsToReturn = remaining < limit ? remaining : limit;

        proposals = new TreePlantingProposal[](itemsToReturn);

        uint256 currentMatch = 0;
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < s_treePlantingProposalCounter && resultIndex < itemsToReturn; i++) {
            if (s_treePlantingProposalIDtoTreePlantingProposal[i].status == status) {
                if (currentMatch >= offset) {
                    proposals[resultIndex] = s_treePlantingProposalIDtoTreePlantingProposal[i];
                    resultIndex++;
                }
                currentMatch++;
            }
        }
        hasMore = offset + itemsToReturn < totalMatching;
        return (proposals, totalMatching, hasMore);
    }

    function voteOnTreePlantingProposal(uint256 proposalID, uint256 vote) external onlyOwner {
        if (proposalID >= s_treePlantingProposalCounter) revert InvalidProposalId();

        TreePlantingProposal storage proposal = s_treePlantingProposalIDtoTreePlantingProposal[proposalID];
        if (proposal.status != 0) revert AlreadyProcessed();
        address[] memory yesVoters = s_treeProposalYesVoters[proposalID];
        address[] memory noVoters = s_treeProposalNoVoters[proposalID];

        for (uint256 i = 0; i < yesVoters.length; i++) {
            if (yesVoters[i] == msg.sender) revert AlreadyVoted();
        }
        for (uint256 i = 0; i < noVoters.length; i++) {
            if (noVoters[i] == msg.sender) revert AlreadyVoted();
        }

        if (vote == 1) {
            s_treeProposalYesVoters[proposalID].push(msg.sender);
        } else {
            s_treeProposalNoVoters[proposalID].push(msg.sender);
        }

        uint256 requiredVotes = (owners.length + 1) / 2;
        if (s_treeProposalYesVoters[proposalID].length >= requiredVotes) {
            proposal.status = 1;
            treeNFTContract.mintNft(
                proposal.latitude,
                proposal.longitude,
                proposal.species,
                proposal.imageUri,
                proposal.qrIpfsHash,
                proposal.geoHash,
                proposal.photos
            );
        } else if (s_treeProposalNoVoters[proposalID].length >= requiredVotes) {
            proposal.status = 2;
        }
    }

    function makeOwner(address newOwner) external onlyOwner {
        // This function allows an owner to add a new owner to the organisation

        if (newOwner == address(0)) revert InvalidAddressInput();
        if (!checkMembership(newOwner)) revert NotOrganisationMember();
        if (checkOwnership(newOwner)) revert AlreadyOwner();
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

    function changePaginationLimit(uint256 _limit) external onlyOwner {
        paginationLimit = _limit;
    }
}
