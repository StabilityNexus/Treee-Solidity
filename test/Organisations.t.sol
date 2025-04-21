// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "forge-std/Test.sol";
import "../src/TreeeNft.sol";
import "../src/UserActivityContract.sol";
import "../src/structs.sol";

contract TreeNftTest is Test {
    TreeNft public treeNft;
    UserActivityContract public userActivityContract;
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public verifier = address(4);
    uint256 testLatitude = 40123456;  // 40.123456
    uint256 testLongitude = 74987654; // -74.987654
    string testSpecies = "Oak";
    string testImageUri = "ipfs://QmTest123";
    string testQrIpfsHash = "ipfs://QmQrCode123";
    string testGeoHash = "dr5r7p3eng";

    function setUp() public {
        vm.startPrank(deployer);
        userActivityContract = new UserActivityContract();
        treeNft = new TreeNft(address(userActivityContract));
        vm.stopPrank();
    }

    function test_createOrganisation() public {
        vm.startPrank(user1);
        string memory orgName = "Tree Planters";
        string memory orgDesc = "An organization dedicated to planting trees";
        string memory orgPhoto = "ipfs://QmOrgPhoto123";
        uint256 orgId = userActivityContract.createOrganisation(orgName, orgDesc, orgPhoto);
        Organisation memory org = userActivityContract.getOrganisation(orgId);
        assertEq(org.name, orgName);
        assertEq(org.owners[0], user1);
        vm.stopPrank();
    }

    function test_leaveOrganisation_RevertsIfLastOwnerLeaves() public {
        vm.startPrank(user1);
        string memory orgName = "Tree Planters";
        string memory orgDesc = "An organization dedicated to planting trees";
        string memory orgPhoto = "ipfs://QmOrgPhoto123";
        uint256 orgId = userActivityContract.createOrganisation(orgName, orgDesc, orgPhoto);
        vm.expectRevert(NeedAnotherOwner.selector);
        userActivityContract.leaveOrganisation(orgId);
        vm.stopPrank();
    }

    function test_makeOwner() public {
        vm.startPrank(user1);
        string memory orgName = "Tree Planters";
        string memory orgDesc = "An organization dedicated to planting trees";
        string memory orgPhoto = "ipfs://QmOrgPhoto123";
        uint256 orgId = userActivityContract.createOrganisation(orgName, orgDesc, orgPhoto);
        vm.stopPrank();
        vm.startPrank(user2);
        userActivityContract.requestToJoinOrganisation(orgId, "I want to help plant trees");
        vm.stopPrank();
        vm.startPrank(user1);
        userActivityContract.processJoinRequest(0,1); // 1 = approve
        vm.stopPrank();
        vm.startPrank(user2);
        userActivityContract.makeOrganisationOwner(orgId, user2);
        Organisation memory org = userActivityContract.getOrganisation(orgId);
        assertEq(org.owners[1], user2);
        vm.stopPrank();
    }

    function test_leaveOrganisationAfterMakingOwner() public {
        vm.startPrank(user1);
        string memory orgName = "Tree Planters";
        string memory orgDesc = "An organization dedicated to planting trees";
        string memory orgPhoto = "ipfs://QmOrgPhoto123";
        uint256 orgId = userActivityContract.createOrganisation(orgName, orgDesc, orgPhoto);
        vm.stopPrank();
        vm.startPrank(user2);
        userActivityContract.requestToJoinOrganisation(orgId, "I want to help plant trees");
        vm.stopPrank();
        vm.startPrank(user1);
        userActivityContract.processJoinRequest(0, 1); // 1 = approve
        userActivityContract.makeOrganisationOwner(orgId, user2);
        vm.stopPrank();
        vm.startPrank(user2);
        userActivityContract.leaveOrganisation(orgId);
        Organisation memory updatedOrg = userActivityContract.getOrganisation(orgId);
        assertEq(updatedOrg.members.length, 1);
        assertEq(updatedOrg.owners[0], user1);
        vm.stopPrank();
    }
}