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
    function test_MintNftWithOrganisation() public {
        vm.startPrank(user1);
        string memory orgName = "Tree Planters";
        string memory orgDesc = "An organization dedicated to planting trees";
        string memory orgPhoto = "ipfs://QmOrgPhoto123";
        uint256 orgId = userActivityContract.createOrganisation(orgName, orgDesc, orgPhoto);
        Organisation memory org = userActivityContract.getOrganisation(orgId);
        assertEq(org.name, orgName);
        assertEq(org.owners[0], user1);
        vm.stopPrank();
        vm.startPrank(user2);
        userActivityContract.requestToJoinOrganisation(orgId, "I want to help plant trees");
        vm.stopPrank();
        vm.startPrank(user1);
        userActivityContract.processJoinRequest(0, 1); // 1 = approve
        vm.stopPrank();
        vm.startPrank(user2);
        vm.store(
            address(treeNft),
            bytes32(uint256(4)), // s_organisationCounter is the 4th state variable (0-indexed)
            bytes32(uint256(orgId + 1)) // Setting it high enough to include our orgId
        );
        
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            orgId
        );
        assertEq(treeNft.ownerOf(0), user2);
        string[] memory userNfts = treeNft.getNFTsByUser(user2);
        assertEq(userNfts.length, 1);
        string memory uri = treeNft.tokenURI(0);
        assertTrue(bytes(uri).length > 0);
        assertTrue(bytes(userNfts[0]).length > 0);
        vm.stopPrank();
    }

    function test_MintNftWithoutOrganisation() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max
        );
        assertEq(treeNft.ownerOf(0), user1);
        string[] memory userNfts = treeNft.getNFTsByUser(user1);
        assertEq(userNfts.length, 1);
        assertTrue(bytes(userNfts[0]).length > 0);
        vm.stopPrank();
    }

    function test_VerifyTree() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max // No organization
        );
        vm.stopPrank();
        vm.startPrank(verifier);
        treeNft.verify(0);
        bool isVerified = treeNft.isVerified(0, verifier);
        assertTrue(isVerified);
        string[] memory verifiedTrees = treeNft.getVerifiedTreesByUser(verifier);
        assertEq(verifiedTrees.length, 1);
        assertTrue(bytes(verifiedTrees[0]).length > 0);
        vm.stopPrank();
    }

    function test_MarkTreeDead() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max 
        );
        treeNft.markDead(0);
        string[] memory userNfts = treeNft.getNFTsByUser(user1);
        assertEq(userNfts.length, 1);
        assertTrue(bytes(userNfts[0]).length > 0);
        vm.stopPrank();
    }

    function test_GetAllNFTs() public {
        // Step 1: User1 mints an NFT
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max
        );
        vm.stopPrank();
        vm.startPrank(user2);
        treeNft.mintNft(
            testLatitude + 1000,
            testLongitude + 1000,
            "Maple",   
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max
        );
        vm.stopPrank();
        string[] memory allNfts = treeNft.getAllNFTs();
        assertEq(allNfts.length, 2);
        assertTrue(bytes(allNfts[0]).length > 0);
        assertTrue(bytes(allNfts[1]).length > 0);
    }
    
    function test_GetNFTsByUser() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "ipfs://QmInitialPhoto123";
        treeNft.mintNft(
            testLatitude,
            testLongitude,
            testSpecies,
            testImageUri,
            testQrIpfsHash,
            testGeoHash,
            initialPhotos,
            type(uint256).max
        );
        vm.stopPrank();
        string[] memory userNfts = treeNft.getNFTsByUser(user1);
        assertEq(userNfts.length, 1);
        assertTrue(bytes(userNfts[0]).length > 0);    
    }
}