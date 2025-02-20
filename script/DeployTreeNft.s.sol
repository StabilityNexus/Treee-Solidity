// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Script} from "forge-std/Script.sol"; 
import {TreeNft} from "../src/TreeeNft.sol";

contract DeployTreeNft is Script {
    string public constant TREE_IMAGE_URI = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwMCIgdmlld0JveD0iMCAwIDIwMCAzMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPCEtLSBHcm91bmQgLS0+CiAgPHJlY3QgeD0iMCIgeT0iMjcwIiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjMwIiBmaWxsPSIjOEI0NTEzIi8+CgogIDwhLS0gVHJ1bmsgLS0+CiAgPHJlY3QgeD0iOTUiIHk9IjE1MCIgd2lkdGg9IjEwIiBoZWlnaHQ9IjEyMCIgZmlsbD0iIzZCNDIyNiIvPgoKICA8IS0tIExlZnQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDODAgMTMwLCA2MCAxMTAsIDcwIDkwIEM4MCA3MCwgMTAwIDgwLCAxMDAgMTAwIiBmaWxsPSIjMjI4QjIyIi8+CgogIDwhLS0gUmlnaHQgTGVhZiAtLT4KICA8cGF0aCBkPSJNMTAwIDE1MCBDMTIwIDEzMCwgMTQwIDExMCwgMTMwIDkwIEMxMjAgNzAsIDEwMCA4MCwgMTAwIDEwMCIgZmlsbD0iIzIyOEIyMiIvPgoKICA8IS0tIFN1bmxpZ2h0IEdsb3cgLS0+CiAgPGNpcmNsZSBjeD0iMTAwIiBjeT0iNTAiIHI9IjMwIiBmaWxsPSJ5ZWxsb3ciIG9wYWNpdHk9IjAuMyIvPgo8L3N2Zz4=";
    
    function run() external returns (TreeNft) {
        string memory treeSvg = vm.readFile("./img/Sappling.svg");
        TreeNft treeNft;
        if (block.number > 1) { // This is a simple way to detect if we're in a test
            treeNft = new TreeNft(svgToImageURI(treeSvg));
        } else {
            vm.startBroadcast();
            treeNft = new TreeNft(svgToImageURI(treeSvg));
            vm.stopBroadcast();
        }
        return treeNft;
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }
}