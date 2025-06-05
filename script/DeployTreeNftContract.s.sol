// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TreeNft.sol";
import "../src/token-contracts/CareToken.sol";
import "../src/token-contracts/PlanterToken.sol";
import "../src/token-contracts/VerifierToken.sol";
import "../src/token-contracts/LegacyToken.sol";

contract DeployTreeNft is Script {
    address public careTokenAddress;
    address public planterTokenAddress;
    address public verifierTokenAddress;
    address public legacyTokenAddress;
    address public treeNftAddress;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Step 1: Deploy ERC20 token contracts with deployer as temporary owner...");

        CareToken careToken = new CareToken(deployer);
        careTokenAddress = address(careToken);
        console.log("CareToken deployed at:", careTokenAddress);

        PlanterToken planterToken = new PlanterToken(deployer);
        planterTokenAddress = address(planterToken);
        console.log("PlanterToken deployed at:", planterTokenAddress);

        VerifierToken verifierToken = new VerifierToken(deployer);
        verifierTokenAddress = address(verifierToken);
        console.log("VerifierToken deployed at:", verifierTokenAddress);

        LegacyToken legacyToken = new LegacyToken(deployer);
        legacyTokenAddress = address(legacyToken);
        console.log("LegacyToken deployed at:", legacyTokenAddress);
        console.log("Step 2: Deploy TreeNft contract...");

        TreeNft treeNft = new TreeNft(careTokenAddress, planterTokenAddress, verifierTokenAddress, legacyTokenAddress);
        treeNftAddress = address(treeNft);
        console.log("TreeNft deployed at:", treeNftAddress);
        console.log("Step 3: Transfer ownership to TreeNft contract...");
        careToken.transferOwnership(treeNftAddress);
        console.log("CareToken ownership transferred to TreeNft");
        planterToken.transferOwnership(treeNftAddress);
        console.log("PlanterToken ownership transferred to TreeNft");
        verifierToken.transferOwnership(treeNftAddress);
        console.log("VerifierToken ownership transferred to TreeNft");
        legacyToken.transferOwnership(treeNftAddress);
        console.log("LegacyToken ownership transferred to TreeNft");
        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("CareToken:", careTokenAddress);
        console.log("PlanterToken:", planterTokenAddress);
        console.log("VerifierToken:", verifierTokenAddress);
        console.log("LegacyToken:", legacyTokenAddress);
        console.log("TreeNft:", treeNftAddress);
        console.log("All token ownerships transferred to TreeNft!");
        console.log("========================\n");
        verifyDeployment();
    }

    function verifyDeployment() internal view {
        console.log("Verifying deployment...");
        TreeNft treeNft = TreeNft(treeNftAddress);

        require(address(treeNft.careTokenContract()) == careTokenAddress, "CareToken address mismatch");
        require(address(treeNft.planterTokenContract()) == planterTokenAddress, "PlanterToken address mismatch");
        require(address(treeNft.verifierTokenContract()) == verifierTokenAddress, "VerifierToken address mismatch");
        require(address(treeNft.legacyToken()) == legacyTokenAddress, "LegacyToken address mismatch");

        CareToken careToken = CareToken(careTokenAddress);
        require(careToken.owner() == treeNftAddress, "CareToken ownership not transferred");
        console.log("Deployment verification successful!");
    }
}
