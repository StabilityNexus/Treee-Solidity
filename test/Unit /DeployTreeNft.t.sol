// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {DeployTreeNft} from "../../script/DeployTreeNft.s.sol";
import {TreeNft} from "../../src/TreeeNft.sol";

contract TreeNftTest is Test {
    DeployTreeNft public deployer;
    TreeNft public treeNft;
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");

    function setUp() public {
        deployer = new DeployTreeNft();
        treeNft = deployer.run();
    }

    function testVerificationOfNFTS() public {
        uint256 latitude = 100;
        uint256 longitude = 150;
        uint256 data = 200;
        vm.deal(USER1, 1 ether);
        vm.prank(USER1);
        treeNft.mintNft(latitude, longitude, data);
        assertEq(treeNft.ownerOf(0), USER1);

        vm.deal(USER2, 1 ether);
        vm.prank(USER2);
        treeNft.mintNft(latitude, longitude, data);
        assertEq(treeNft.ownerOf(1), USER2);

        vm.prank(USER2);
        treeNft.verify(0);
        assertEq(treeNft.isVerified(0, USER2), true);
    }
}