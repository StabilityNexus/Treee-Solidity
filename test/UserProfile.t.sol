// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "forge-std/Test.sol";
import "../src/TreeeNft.sol";
import "../src/UserActivityContract.sol";
import "../src/structs.sol";

contract UserProfileTest is Test {
    TreeNft public treeNft;
    UserActivityContract public userActivityContract;
    address public deployer = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public verifier = address(4);
    string public testName1 = "John Doe";
    string public testName2 = "Jane Smith";
    string public testProfilePhotoIpfs1 = "ipfs://QmTest123";
    string public testProfilePhotoIpfs2 = "A passionate tree planter";

    function setUp() public {
        vm.startPrank(deployer);
        userActivityContract = new UserActivityContract();
        treeNft = new TreeNft(address(userActivityContract));
        vm.stopPrank();
    }

    function test_CreateUserProfile() public {
        vm.startPrank(user1);
        userActivityContract.initialiseUserProfile(testProfilePhotoIpfs1,testName1);
        User memory userProfile = userActivityContract.getUserProfile(user1);
        assertEq(userProfile.name, testName1);
        assertEq(userProfile.profilePhotoIpfs, testProfilePhotoIpfs1);
        vm.stopPrank();
    }

    function test_updateUsername() public {
        vm.startPrank(user1);
        userActivityContract.initialiseUserProfile(testProfilePhotoIpfs1,testName1);
        userActivityContract.updateUsername(testName2);
        User memory userProfile = userActivityContract.getUserProfile(user1);
        assertEq(userProfile.name, testName2);
        assertEq(userProfile.profilePhotoIpfs, testProfilePhotoIpfs1);
        vm.stopPrank();
    }

    function test_updateProfilePhoto() public {
        vm.startPrank(user1);
        userActivityContract.initialiseUserProfile(testProfilePhotoIpfs1,testName1);
        userActivityContract.updateUserProfilePhoto(testProfilePhotoIpfs2);
        User memory userProfile = userActivityContract.getUserProfile(user1);
        assertEq(userProfile.name, testName1);
        assertEq(userProfile.profilePhotoIpfs, testProfilePhotoIpfs2);
        vm.stopPrank();
    }

}