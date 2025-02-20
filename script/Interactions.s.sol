// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {TreeNft} from "../src/TreeeNft.sol";

contract MintTreeNft is Script {
    string public constant TREE_URI =
        "data:application/json;base64,eyJuYW1lIjoiVHJlZU5GVCAjMCIsICJkZXNjcmlwdGlvbiI6IkEgVHJlZSBORlQgZm9yIHBsYW50aW5nIGEgdHJlZSIsICJhdHRyaWJ1dGVzIjogW3sidHJhaXRfdHlwZSI6ICJMYXRpdHVkZSIsICJ2YWx1ZSI6ICIxMDAifSwgeyJ0cmFpdF90eXBlIjogIkxvbmdpdHVkZSIsICJ2YWx1ZSI6ICIxNTAifSwgeyJ0cmFpdF90eXBlIjogIkRhdGEiLCAidmFsdWUiOiAiMjAwIn0sIHsidHJhaXRfdHlwZSI6ICJWZXJpZmllcnMiLCAidmFsdWUiOiAiTm9uZSJ9XSwgImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTWpBd0lpQm9aV2xuYUhROUlqTXdNQ0lnZG1sbGQwSnZlRDBpTUNBd0lESXdNQ0F6TURBaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJK0NpQWdQQ0V0TFNCSGNtOTFibVFnTFMwK0NpQWdQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlNakF3SWlCb1pXbG5hSFE5SWpNd0lpQm1hV3hzUFNJak9FSTBOVEV6SWk4K0Nnb2dJRHdoTFMwZ1ZISjFibXNnTFMwK0NpQWdQSEpsWTNRZ2VEMGlPVFVpSUhrOUlqRTFNQ0lnZDJsa2RHZzlJakV3SWlCb1pXbG5hSFE5SWpFeU1DSWdabWxzYkQwaUl6WkNOREl5TmlJdlBnb0tJQ0E4SVMwdElFeGxablFnVEdWaFppQXRMVDRLSUNBOGNHRjBhQ0JrUFNKTk1UQXdJREUxTUNCRE9EQWdNVE13TENBMk1DQXhNVEFzSURjd0lEa3dJRU00TUNBM01Dd2dNVEF3SURnd0xDQXhNREFnTVRBd0lpQm1hV3hzUFNJak1qSTRRakl5SWk4K0Nnb2dJRHdoTFMwZ1VtbG5hSFFnVEdWaFppQXRMVDRLSUNBOGNHRjBhQ0JrUFNKTk1UQXdJREUxTUNCRE1USXdJREV6TUN3Z01UUXdJREV4TUN3Z01UTXdJRGt3SUVNeE1qQWdOekFzSURFd01DQTRNQ3dnTVRBd0lERXdNQ0lnWm1sc2JEMGlJekl5T0VJeU1pSXZQZ29LSUNBOElTMHRJRk4xYm14cFoyaDBJRWRzYjNjZ0xTMCtDaUFnUEdOcGNtTnNaU0JqZUQwaU1UQXdJaUJqZVQwaU5UQWlJSEk5SWpNd0lpQm1hV3hzUFNKNVpXeHNiM2NpSUc5d1lXTnBkSGs5SWpBdU15SXZQZ284TDNOMlp6ND0ifQ==";

    function run() external {
        address mostRecentlyDeployedBasicNft = DevOpsTools.get_most_recent_deployment("TreeNft", block.chainid);
        mintNftOnContract(mostRecentlyDeployedBasicNft);
    }

    function mintNftOnContract(address basicNftAddress) public {
        vm.startBroadcast();
        uint256 latitude = 100;
        uint256 longitude = 150;
        uint256 data = 200;
        TreeNft(basicNftAddress).mintNft(latitude, longitude, data);    
        vm.stopBroadcast();
    }
}

// contract MintMoodNft is Script {
//     function run() external {
//         address mostRecentlyDeployedMoodNft = DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);
//         mintNftOnContract(mostRecentlyDeployedMoodNft);
//     }

//     function mintNftOnContract(address moodNftAddress) public {
//         vm.startBroadcast();
//         MoodNft(moodNftAddress).mintNft();
//         vm.stopBroadcast();
//     }
// }

// contract FlipMoodNft is Script {
//     uint256 public constant TOKEN_ID_TO_FLIP = 0;

//     function run() external {
//         address mostRecentlyDeployedMoodNft = DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);
//         flipMoodNft(mostRecentlyDeployedMoodNft);
//     }

//     function flipMoodNft(address moodNftAddress) public {
//         vm.startBroadcast();
//         MoodNft(moodNftAddress).flipMood(TOKEN_ID_TO_FLIP);
//         vm.stopBroadcast();
//     }
// }
