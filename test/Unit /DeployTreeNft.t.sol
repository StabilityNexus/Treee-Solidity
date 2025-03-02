// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployTreeNft} from "../../script/DeployTreeNft.s.sol";
import {TreeNft} from "../../src/TreeeNft.sol";

contract TreeNftTest is Test {
    DeployTreeNft public deployer;
    TreeNft public treeNft;
    string public constant TREE_IMAGE_URI =
        "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwMCIgdmlld0JveD0iMCAwIDIwMCAzMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPCEtLSBHcm91bmQgLS0+CiAgPHJlY3QgeD0iMCIgeT0iMjcwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwIiBmaWxsPSIjOEI0NTEzIi8+CgogIDwhLS0gVHJ1bmsgLS0+CiAgPHJlY3QgeD0iOTUiIHk9IjE1MCIgd2lkdGg9IjEwIiBoZWlnaHQ9IjEyMCIgZmlsbD0iIzZCNDIyNiIvPgoKICA8IS0tIExlZnQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDODAgMTMwLCA2MCAxMTAsIDcwIDkwIEM4MCA3MCwgMTAwIDgwLCAxMDAgMTAwIiBmaWxsPSIjMjI4QjIyIi8+CgogIDwhLS0gUmlnaHQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDMTIwIDEzMCwgMTQwIDExMCwgMTMwIDkwIEMxMjAgNzAsIDEwMCA4MCwgMTAwIDEwMCIgZmlsbD0iIzIyOEIyMiIvPgoKICA8IS0tIFN1bmxpZ2h0IEdsb3cgLS0+CiAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iNTAiIHI9IjMwIiBmaWxsPSJ5ZWxsb3ciIG9wYWNpdHk9IjAuMyIvPgo8L3N2Zz4=";
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");

    function setUp() public {
        deployer = new DeployTreeNft();
        treeNft = deployer.run();
    }

    function testVerificationOfNFTS() public {
        uint256 latitude = 100;
        uint256 longitude = 150;
        string memory species = "Pine";
        vm.deal(USER1, 1 ether);
        vm.prank(USER1);
        treeNft.mintNft(latitude, longitude, species, TREE_IMAGE_URI);
        assertEq(treeNft.ownerOf(0), USER1);

        vm.deal(USER2, 1 ether);
        vm.prank(USER2);
        treeNft.mintNft(latitude, longitude, species, TREE_IMAGE_URI);
        assertEq(treeNft.ownerOf(1), USER2);

        vm.prank(USER2);
        treeNft.verify(0);
        assertEq(treeNft.isVerified(0, USER2), true);
    }
}
