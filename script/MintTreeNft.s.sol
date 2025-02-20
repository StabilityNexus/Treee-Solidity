// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {TreeNft} from "../src/TreeeNft.sol";

contract MintTreeNFT is Script {
    string public constant TREE_IMAGE_URI = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwMCIgdmlld0JveD0iMCAwIDIwMCAzMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPCEtLSBHcm91bmQgLS0+CiAgPHJlY3QgeD0iMCIgeT0iMjcwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwIiBmaWxsPSIjOEI0NTEzIi8+CgogIDwhLS0gVHJ1bmsgLS0+CiAgPHJlY3QgeD0iOTUiIHk9IjE1MCIgd2lkdGg9IjEwIiBoZWlnaHQ9IjEyMCIgZmlsbD0iIzZCNDIyNiIvPgoKICA8IS0tIExlZnQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDODAgMTMwLCA2MCAxMTAsIDcwIDkwIEM4MCA3MCwgMTAwIDgwLCAxMDAgMTAwIiBmaWxsPSIjMjI4QjIyIi8+CgogIDwhLS0gUmlnaHQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDMTIwIDEzMCwgMTQwIDExMCwgMTMwIDkwIEMxMjAgNzAsIDEwMCA4MCwgMTAwIDEwMCIgZmlsbD0iIzIyOEIyMiIvPgoKICA8IS0tIFN1bmxpZ2h0IEdsb3cgLS0+CiAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iNTAiIHI9IjMwIiBmaWxsPSJ5ZWxsb3ciIG9wYWNpdHk9IjAuMyIvPgo8L3N2Zz4=";
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // address contractAddress = 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141;

        vm.startBroadcast(privateKey);
        TreeNft treeNft = new TreeNft(TREE_IMAGE_URI);
        treeNft.mintNft(12345, 67890, 20240220); // Example latitude, longitude, and data
        vm.stopBroadcast();
    }
}
