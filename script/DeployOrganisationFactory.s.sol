// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TreeNft.sol";
import "../src/OrganisationFactory.sol";

contract DeployOrganisationFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address treeNftAddress = vm.envAddress("TREE_NFT_ADDRESS");

        console.log("\n========== DEPLOYMENT STARTED ==========");
        console.log(">> Deployer Address:        ", deployer);
        console.log(">> Deployer Balance (wei):  ", deployer.balance);
        console.log(">> Linked TreeNFT Address:  ", treeNftAddress);
        console.log("========================================\n");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying OrganisationFactory...");
        OrganisationFactory orgFactory = new OrganisationFactory(treeNftAddress);
        address orgFactoryAddress = address(orgFactory);
        console.log("OrganisationFactory deployed at:", orgFactoryAddress);

        vm.stopBroadcast();

        console.log("\n========== DEPLOYMENT SUMMARY ==========");
        console.log("OrganisationFactory Address: ", orgFactoryAddress);
        console.log("Linked TreeNFT Address:      ", treeNftAddress);
        console.log("Deployment completed successfully.");
        console.log("========================================\n");
    }
}
