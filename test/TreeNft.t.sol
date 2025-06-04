// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TreeNft.sol";
import "../src/utils/structs.sol";
import "../src/utils/errors.sol";

contract TreeNftTest is Test {
    TreeNft public treeNft;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public verifier1 = address(0x4);
    address public verifier2 = address(0x5);
    address public organisation = address(0x6);

    // Sample tree data
    uint256 constant LATITUDE = 1234567;
    uint256 constant LONGITUDE = 9876543;
    string constant SPECIES = "Oak Tree";
    string constant IMAGE_URI = "ipfs://QmSampleImageHash";
    string constant QR_IPFS_HASH = "QmSampleQRHash";
    string constant GEO_HASH = "u4pruydqqvj";

    function setUp() public {
        vm.prank(owner);
        treeNft = new TreeNft();
    }

    function test_MintNft() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](2);
        initialPhotos[0] = "photo1.jpg";
        initialPhotos[1] = "photo2.jpg";

        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        assertEq(treeNft.ownerOf(0), user1);
        assertEq(treeNft.balanceOf(user1), 1);

        Tree memory tree = treeNft.getTreeDetailsbyID(0);
        assertEq(tree.latitude, LATITUDE);
        assertEq(tree.longitude, LONGITUDE);
        assertEq(tree.species, SPECIES);
        assertEq(tree.imageUri, IMAGE_URI);
        assertEq(tree.qrIpfsHash, QR_IPFS_HASH);
        assertEq(tree.geoHash, GEO_HASH);
        assertEq(tree.death, type(uint256).max);
        assertEq(tree.ancestors[0], user1);
        assertEq(tree.photos.length, 2);
        assertEq(tree.photos[0], "photo1.jpg");
        assertEq(tree.photos[1], "photo2.jpg");
    }

    function test_MintMultipleNfts() public {
        vm.startPrank(user1);

        string[] memory initialPhotos = new string[](0);

        // Mint first NFT
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        // Mint second NFT
        treeNft.mintNft(
            LATITUDE + 1000,
            LONGITUDE + 1000,
            "Pine Tree",
            "ipfs://QmPineImage",
            "QmPineQR",
            "u4pruydqqvk",
            initialPhotos
        );

        vm.stopPrank();

        assertEq(treeNft.balanceOf(user1), 2);
        assertEq(treeNft.ownerOf(0), user1);
        assertEq(treeNft.ownerOf(1), user1);
        Tree[] memory userTrees = treeNft.getNFTsByUser(user1);
        assertEq(userTrees.length, 2);
        assertEq(userTrees[0].species, SPECIES);
        assertEq(userTrees[1].species, "Pine Tree");
    }

    function test_TokenURI() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);

        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        string memory uri = treeNft.tokenURI(0);
        assertTrue(bytes(uri).length > 0);
        assertEq(
            keccak256(abi.encodePacked(substring(uri, 0, 29))),
            keccak256(abi.encodePacked("data:application/json;base64,"))
        );
    }

    function test_TokenURIInvalidToken() public {
        vm.expectRevert(InvalidTreeID.selector);
        treeNft.tokenURI(999);
    }

    function test_GetAllNFTs() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);

        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        treeNft.mintNft(LATITUDE + 1, LONGITUDE + 1, "Pine", IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        vm.stopPrank();

        Tree[] memory allTrees = treeNft.getAllNFTs();
        assertEq(allTrees.length, 2);
        assertEq(allTrees[0].species, SPECIES);
        assertEq(allTrees[1].species, "Pine");
    }

    function test_GetRecentTreesPaginated() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);

        // Mint 5 trees
        for (uint256 i = 0; i < 5; i++) {
            treeNft.mintNft(
                LATITUDE + i,
                LONGITUDE + i,
                string(abi.encodePacked("Tree", vm.toString(i))),
                IMAGE_URI,
                QR_IPFS_HASH,
                GEO_HASH,
                initialPhotos
            );
        }
        vm.stopPrank();
        (Tree[] memory trees, uint256 totalCount, bool hasMore) = treeNft.getRecentTreesPaginated(0, 3);

        assertEq(trees.length, 3);
        assertEq(totalCount, 5);
        assertTrue(hasMore);
        assertEq(trees[0].species, "Tree4");
        assertEq(trees[1].species, "Tree3");
        assertEq(trees[2].species, "Tree2");
        (Tree[] memory remainingTrees, uint256 totalCount2, bool hasMore2) = treeNft.getRecentTreesPaginated(3, 3);

        assertEq(remainingTrees.length, 2);
        assertEq(totalCount2, 5);
        assertFalse(hasMore2);
        assertEq(remainingTrees[0].species, "Tree1");
        assertEq(remainingTrees[1].species, "Tree0");
    }

    function test_GetRecentTreesPaginatedLimitExceeded() public {
        vm.expectRevert(PaginationLimitExceeded.selector);
        treeNft.getRecentTreesPaginated(0, 51);
    }

    function testGetNFTsByUserPaginated() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);
        for (uint256 i = 0; i < 4; i++) {
            treeNft.mintNft(
                LATITUDE + i,
                LONGITUDE + i,
                string(abi.encodePacked("UserTree", vm.toString(i))),
                IMAGE_URI,
                QR_IPFS_HASH,
                GEO_HASH,
                initialPhotos
            );
        }
        vm.stopPrank();
        (Tree[] memory trees, uint256 totalCount) = treeNft.getNFTsByUserPaginated(user1, 0, 2);

        assertEq(trees.length, 2);
        assertEq(totalCount, 4);
        assertEq(trees[0].species, "UserTree0");
        assertEq(trees[1].species, "UserTree1");

        (Tree[] memory remainingTrees, uint256 totalCount2) = treeNft.getNFTsByUserPaginated(user1, 2, 2);

        assertEq(remainingTrees.length, 2);
        assertEq(totalCount2, 4);
        assertEq(remainingTrees[0].species, "UserTree2");
        assertEq(remainingTrees[1].species, "UserTree3");
    }

    function test_GetTreeDetailsbyIDInvalid() public {
        vm.expectRevert(InvalidTreeID.selector);
        treeNft.getTreeDetailsbyID(999);
    }

    function test_Verify() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.prank(verifier1);
        string[] memory proofHashes = new string[](2);
        proofHashes[0] = "proof1";
        proofHashes[1] = "proof2";

        treeNft.verify(0, proofHashes, "Tree looks healthy");

        assertTrue(treeNft.isVerified(0, verifier1));

        TreeNftVerification[] memory verifications = treeNft.getTreeNftVerifiers(0);
        assertEq(verifications.length, 1);
        assertEq(verifications[0].verifier, verifier1);
        assertEq(verifications[0].description, "Tree looks healthy");
        assertEq(verifications[0].proofHashes.length, 2);
        assertEq(verifications[0].proofHashes[0], "proof1");
        assertEq(verifications[0].proofHashes[1], "proof2");
        assertFalse(verifications[0].isHidden);
    }

    function test_VerifyInvalidToken() public {
        vm.prank(verifier1);
        string[] memory proofHashes = new string[](0);

        vm.expectRevert(InvalidTreeID.selector);
        treeNft.verify(999, proofHashes, "Invalid tree");
    }

    function test_VerifyTwiceSameVerifier() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.startPrank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof1";

        treeNft.verify(0, proofHashes, "First verification");
        treeNft.verify(0, proofHashes, "Second verification");
        vm.stopPrank();

        TreeNftVerification[] memory verifications = treeNft.getTreeNftVerifiers(0);
        assertEq(verifications.length, 1);
        assertEq(verifications[0].description, "First verification");
    }

    function test_MultipleVerifiers() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        vm.prank(verifier1);
        string[] memory proofHashes1 = new string[](1);
        proofHashes1[0] = "proof1";
        treeNft.verify(0, proofHashes1, "Verifier 1 says OK");

        vm.prank(verifier2);
        string[] memory proofHashes2 = new string[](1);
        proofHashes2[0] = "proof2";
        treeNft.verify(0, proofHashes2, "Verifier 2 says OK");

        assertTrue(treeNft.isVerified(0, verifier1));
        assertTrue(treeNft.isVerified(0, verifier2));

        TreeNftVerification[] memory verifications = treeNft.getTreeNftVerifiers(0);
        assertEq(verifications.length, 2);
    }

    function test_RemoveVerification() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.prank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof1";
        treeNft.verify(0, proofHashes, "Verification");

        vm.prank(user1);
        vm.expectEmit(true, true, true, false);
        emit TreeNft.VerificationRemoved(0, 0, verifier1);
        treeNft.removeVerification(0);

        TreeNftVerification[] memory verifications = treeNft.getTreeNftVerifiers(0);
        assertEq(verifications.length, 1);
    }

    function test_RemoveVerificationNotOwner() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.prank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof1";
        treeNft.verify(0, proofHashes, "Verification");

        vm.prank(user2);
        vm.expectRevert(NotTreeOwner.selector);
        treeNft.removeVerification(0);
    }

    function test_GetVerifiedTreesByUser() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, "Tree1", IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        treeNft.mintNft(LATITUDE + 1, LONGITUDE + 1, "Tree2", IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        vm.stopPrank();

        vm.startPrank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof";
        treeNft.verify(0, proofHashes, "OK");
        treeNft.verify(1, proofHashes, "OK");
        vm.stopPrank();

        Tree[] memory verifiedTrees = treeNft.getVerifiedTreesByUser(verifier1);
        assertEq(verifiedTrees.length, 2);
        assertEq(verifiedTrees[0].species, "Tree1");
        assertEq(verifiedTrees[1].species, "Tree2");
    }

    function test_GetVerifiedTreesByUserPaginated() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);
        for (uint256 i = 0; i < 5; i++) {
            treeNft.mintNft(
                LATITUDE + i,
                LONGITUDE + i,
                string(abi.encodePacked("Tree", vm.toString(i))),
                IMAGE_URI,
                QR_IPFS_HASH,
                GEO_HASH,
                initialPhotos
            );
        }
        vm.stopPrank();
        vm.startPrank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof";
        for (uint256 i = 0; i < 5; i++) {
            treeNft.verify(i, proofHashes, "OK");
        }
        vm.stopPrank();

        (Tree[] memory trees, uint256 totalCount) = treeNft.getVerifiedTreesByUserPaginated(verifier1, 0, 3);

        assertEq(trees.length, 3);
        assertEq(totalCount, 5);
        assertEq(trees[0].species, "Tree0");
        assertEq(trees[1].species, "Tree1");
        assertEq(trees[2].species, "Tree2");
    }

    function test_GetTreeNftVerifiersPaginated() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "proof";

        address[] memory verifiers = new address[](5);
        verifiers[0] = address(0x10);
        verifiers[1] = address(0x11);
        verifiers[2] = address(0x12);
        verifiers[3] = address(0x13);
        verifiers[4] = address(0x14);

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(verifiers[i]);
            treeNft.verify(0, proofHashes, string(abi.encodePacked("Verification", vm.toString(i))));
        }

        (TreeNftVerification[] memory verifications, uint256 totalCount, uint256 visibleCount) =
            treeNft.getTreeNftVerifiersPaginated(0, 0, 3);

        assertEq(verifications.length, 3);
        assertEq(totalCount, 5);
        assertEq(visibleCount, 5);
        assertEq(verifications[0].verifier, verifiers[0]);
        assertEq(verifications[1].verifier, verifiers[1]);
        assertEq(verifications[2].verifier, verifiers[2]);
    }

    function test_MarkDead() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        vm.warp(block.timestamp + 366 days);
        vm.prank(user1);
        treeNft.markDead(0);

        Tree memory tree = treeNft.getTreeDetailsbyID(0);
        assertTrue(tree.death != type(uint256).max);
        assertEq(tree.death, block.timestamp);
    }

    function testMarkDeadNotOwner() public {
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.prank(user2);
        vm.expectRevert(NotTreeOwner.selector);
        treeNft.markDead(0);
    }

    function testMarkDeadInvalidToken() public {
        vm.prank(user1);
        vm.expectRevert(InvalidTreeID.selector);
        treeNft.markDead(999);
    }

    function testMarkDeadAlreadyDead() public {
        vm.startPrank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        vm.warp(block.timestamp + 366 days);
        treeNft.markDead(0);

        vm.expectRevert(TreeAlreadyDead.selector);
        treeNft.markDead(0);
        vm.stopPrank();
    }

    function testRegisterUserProfile() public {
        vm.prank(user1);
        treeNft.registerUserProfile("John Doe", "QmProfileHash");
    }

    function testRegisterUserProfileAlreadyRegistered() public {
        vm.startPrank(user1);
        treeNft.registerUserProfile("John Doe", "QmProfileHash");

        vm.expectRevert(UserAlreadyRegistered.selector);
        treeNft.registerUserProfile("Jane Doe", "QmProfileHash2");
        vm.stopPrank();
    }

    function testUpdateUserDetails() public {
        vm.startPrank(user1);
        treeNft.registerUserProfile("John Doe", "QmProfileHash");
        treeNft.updateUserDetails("John Smith", "QmNewProfileHash");
        vm.stopPrank();
    }

    function testUpdateUserDetailsNotRegistered() public {
        vm.prank(user1);
        vm.expectRevert(UserNotRegistered.selector);
        treeNft.updateUserDetails("John Doe", "QmProfileHash");
    }

    /// Helper functions
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function testCompleteWorkflow() public {
        vm.prank(user1);
        treeNft.registerUserProfile("Tree Planter", "QmPlanterHash");

        vm.prank(verifier1);
        treeNft.registerUserProfile("Tree Verifier", "QmVerifierHash");

        vm.prank(user1);
        string[] memory initialPhotos = new string[](1);
        initialPhotos[0] = "initial_photo.jpg";
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);

        vm.prank(verifier1);
        string[] memory proofHashes = new string[](1);
        proofHashes[0] = "verification_proof.jpg";
        treeNft.verify(0, proofHashes, "Tree is healthy and growing well");

        Tree memory tree = treeNft.getTreeDetailsbyID(0);
        assertEq(tree.species, SPECIES);
        assertEq(treeNft.ownerOf(0), user1);
        assertTrue(treeNft.isVerified(0, verifier1));

        TreeNftVerification[] memory verifications = treeNft.getTreeNftVerifiers(0);
        assertEq(verifications.length, 1);
        assertEq(verifications[0].verifier, verifier1);

        vm.prank(user1);
        vm.warp(block.timestamp + 366 days);
        treeNft.markDead(0);

        Tree memory deadTree = treeNft.getTreeDetailsbyID(0);
        assertTrue(deadTree.death != type(uint256).max);
    }

    function testGasOptimization() public {
        uint256 gasBefore = gasleft();
        vm.prank(user1);
        string[] memory initialPhotos = new string[](0);
        treeNft.mintNft(LATITUDE, LONGITUDE, SPECIES, IMAGE_URI, QR_IPFS_HASH, GEO_HASH, initialPhotos);
        uint256 gasUsed = gasBefore - gasleft();
        assertTrue(gasUsed < 500000, "Minting uses too much gas");
    }
}
