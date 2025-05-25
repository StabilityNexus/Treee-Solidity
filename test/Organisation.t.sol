// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/OrganisationFactory.sol";
import "../src/Organisation.sol";
import "../src/utils/structs.sol";
import "../src/utils/errors.sol";
import "../src/TreeNft.sol";

contract OrganisationTest is Test {
    OrganisationFactory private factory;
    TreeNft private treeNft;
    address private owner = address(0x1);
    address private user1 = address(0x2);
    address private user2 = address(0x3);
    address private user3 = address(0x4);
    address private user4 = address(0x5);
    uint256 constant LATITUDE = 123456789;
    uint256 constant LONGITUDE = 987654321;
    string constant SPECIES = "Oak";
    string constant IMAGE_URI = "https://example.com/tree.jpg";
    string constant QR_IPFS_HASH = "QmTestQrHash";
    string constant GEOHASH = "u4pruydqqvj";

    string constant NAME = "Test Organisation";
    string constant DESCRIPTION = "This is a test organisation.";
    string constant PHOTO_IPFS_HASH = "QmTestPhotoHash";
    string constant NAME2 = "Test Organisation";
    string constant DESCRIPTION2 = "This is a test organisation.";
    string constant PHOTO_IPFS_HASH2 = "QmTestPhotoHash";

    string constant JOIN_REQUEST_DESCRIPTION = "I want to join this organisation";

    function setUp() public {
        treeNft = new TreeNft();
        vm.startPrank(owner);
        factory = new OrganisationFactory(address(treeNft));
        vm.stopPrank();
    }

    function test_requestToJoinOrganisation() public {
        // This test checks if the requestToJoinOrganisation function works correctly by creating an organisation, requesting to join it, and verifying the request details.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        JoinRequest memory request = Organisation(orgAddress).getJoinRequest(requestId);
        vm.stopPrank();
        assertEq(request.id, requestId);
        assertEq(request.user, user2);
        assertEq(request.organisationContract, orgAddress);
        assertEq(request.status, 0);
        assertEq(request.description, "I want to join this organisation");
    }

    function test_approveJoinRequest() public {
        // This test checks if the approveJoinRequest function works correctly by creating an organisation, requesting to join it, approving the request, and verifying the member details.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId, 1);
        vm.stopPrank();

        vm.prank(user1);
        assertEq(Organisation(orgAddress).getMemberCount(), 2);
        vm.stopPrank();

        vm.prank(user2);
        address[] memory members = Organisation(orgAddress).getMembers();
        vm.stopPrank();

        assertEq(members[0], user1);
        assertEq(members[1], user2);
    }

    function test_denyJoinRequest() public {
        // This test checks if the denyJoinRequest function works correctly by creating an organisation, requesting to join it, denying the request, and verifying the request status.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId, 2);
        vm.stopPrank();

        vm.prank(user1);
        JoinRequest memory request = Organisation(orgAddress).getJoinRequest(requestId);
        vm.stopPrank();

        assertEq(request.status, 2); // Denied
    }

    function test_onlyOwnerModifier() public {
        // This test checks if the onlyOwner modifier works correctly by trying to call a function that requires ownership from a non-owner address.

        vm.prank(owner);
        (, address orgAddress) = factory.createOrganisation(NAME2, DESCRIPTION2, PHOTO_IPFS_HASH2);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert(OnlyOwner.selector);
        Organisation(orgAddress).processJoinRequest(requestId, 2);
        vm.stopPrank();
    }

    function test_leaveOrganisation() public {
        // This test checks if the leaveOrganisation function works correctly by creating an organisation, joining it, and then leaving it.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId, 1);
        vm.stopPrank();

        vm.prank(user2);
        Organisation(orgAddress).leaveOrganisation();
        vm.stopPrank();

        vm.prank(user1);
        assertEq(Organisation(orgAddress).getMemberCount(), 1); // Only owner remains
    }

    function test_leaveOrganisationBeingTheOnlyOwner() public {
        // This test checks if the leaveOrganisation function reverts when the only owner tries to leave the organisation.

        vm.prank(user1);
        (, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId, 1);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(NeedAnotherOwner.selector);
        Organisation(orgAddress).leaveOrganisation();
        vm.stopPrank();
    }

    function test_leaveOrganisationMakingAnotherOwner() public {
        vm.prank(user1);
        (, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId, 1);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).makeOwner(user2);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).leaveOrganisation();
        vm.stopPrank();
    }

    function test_requestVerification() public {
        // This test checks if the requestVerification function works correctly by creating an organisation, requesting verification, and verifying the request details.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId1 = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId1, 1);
        vm.stopPrank();

        vm.prank(user2);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "QmProofHash";
        uint256 requestId = Organisation(orgAddress).requestVerification("Proof of existence", proofHashes, 1);
        vm.stopPrank();

        vm.prank(user1);
        OrganisationVerificationRequest memory request = Organisation(orgAddress).getVerificationRequest(requestId);
        vm.stopPrank();

        assertEq(request.id, requestId);
        assertEq(request.initial_member, user2);
        assertEq(request.organisationContract, orgAddress);
        assertEq(request.status, 0);
        assertEq(request.description, "Proof of existence");
    }

    function test_approveVerification() public {
        // This test checks if the requestVerification function works correctly by creating an organisation, requesting verification, and verifying the request details.

        vm.prank(user1);
        (uint256 orgId, address orgAddress) = factory.createOrganisation(NAME, DESCRIPTION, PHOTO_IPFS_HASH);
        assertEq(orgId, 0);
        vm.stopPrank();

        string[] memory imageHashes = new string[](1);
        imageHashes[0] = "QmProofHash";

        vm.prank(user3);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEOHASH, imageHashes, orgAddress);
        vm.stopPrank();

        vm.prank(user2);
        uint256 requestId1 = Organisation(orgAddress).requestToJoin(JOIN_REQUEST_DESCRIPTION);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).processJoinRequest(requestId1, 1);
        vm.stopPrank();

        vm.prank(user2);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "QmProofHash";
        uint256 requestId = Organisation(orgAddress).requestVerification("Proof of existence", proofHashes, 0);
        vm.stopPrank();

        vm.prank(user1);
        Organisation(orgAddress).voteOnVerificationRequest(requestId, 1);
        OrganisationVerificationRequest memory request = Organisation(orgAddress).getVerificationRequest(requestId);
        vm.stopPrank();

        assertEq(request.status, 1);
    }
}
