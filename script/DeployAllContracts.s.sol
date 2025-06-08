// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TreeNft.sol";
import "../src/token-contracts/CareToken.sol";
import "../src/token-contracts/PlanterToken.sol";
import "../src/token-contracts/VerifierToken.sol";
import "../src/token-contracts/LegacyToken.sol";
import "../src/OrganisationFactory.sol";

contract DeployAllContractsAtOnce is Script {
    address public careTokenAddress;
    address public planterTokenAddress;
    address public verifierTokenAddress;
    address public legacyTokenAddress;
    address public treeNftAddress;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========== DEPLOYMENT INITIALIZED ==========");
        console.log("Deployer Address:          ", deployer);
        console.log("Deployer ETH Balance:      ", deployer.balance);
        console.log("============================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // STEP 1: Deploy token contracts
        console.log(">> Step 1: Deploying ERC20 Token Contracts...");

        CareToken careToken = new CareToken(deployer);
        careTokenAddress = address(careToken);
        console.log("  - CareToken deployed at:        ", careTokenAddress);

        PlanterToken planterToken = new PlanterToken(deployer);
        planterTokenAddress = address(planterToken);
        console.log("  - PlanterToken deployed at:     ", planterTokenAddress);

        VerifierToken verifierToken = new VerifierToken(deployer);
        verifierTokenAddress = address(verifierToken);
        console.log("  - VerifierToken deployed at:    ", verifierTokenAddress);

        LegacyToken legacyToken = new LegacyToken(deployer);
        legacyTokenAddress = address(legacyToken);
        console.log("  - LegacyToken deployed at:      ", legacyTokenAddress);

        console.log("\n>> Step 2: Deploying TreeNft Contract...");
        TreeNft treeNft = new TreeNft(careTokenAddress, planterTokenAddress, verifierTokenAddress, legacyTokenAddress);
        treeNftAddress = address(treeNft);
        console.log("  - TreeNft deployed at:          ", treeNftAddress);

        console.log("\n>> Step 3: Transferring Token Ownership to TreeNft...");
        careToken.transferOwnership(treeNftAddress);
        console.log("  - CareToken ownership transferred.");
        planterToken.transferOwnership(treeNftAddress);
        console.log("  - PlanterToken ownership transferred.");
        verifierToken.transferOwnership(treeNftAddress);
        console.log("  - VerifierToken ownership transferred.");
        legacyToken.transferOwnership(treeNftAddress);
        console.log("  - LegacyToken ownership transferred.");

        console.log("\n>> Step 4: Deploying OrganisationFactory...");
        OrganisationFactory orgFactory = new OrganisationFactory(treeNftAddress);
        address orgFactoryAddress = address(orgFactory);
        console.log("  - OrganisationFactory deployed at:", orgFactoryAddress);

        vm.stopBroadcast();

        console.log("\n========== DEPLOYMENT SUMMARY ==========");
        console.log("CareToken Address:         ", careTokenAddress);
        console.log("PlanterToken Address:      ", planterTokenAddress);
        console.log("VerifierToken Address:     ", verifierTokenAddress);
        console.log("LegacyToken Address:       ", legacyTokenAddress);
        console.log("TreeNft Address:           ", treeNftAddress);
        console.log("OrganisationFactory:       ", orgFactoryAddress);
        console.log("All token ownerships successfully transferred to TreeNft.");
        console.log("=========================================\n");

        verifyDeployment();
    }

    function verifyDeployment() internal view {
        console.log(">> Verifying Deployment Integrity...");

        TreeNft treeNft = TreeNft(treeNftAddress);

        require(address(treeNft.careTokenContract()) == careTokenAddress, "CareToken address mismatch");
        require(address(treeNft.planterTokenContract()) == planterTokenAddress, "PlanterToken address mismatch");
        require(address(treeNft.verifierTokenContract()) == verifierTokenAddress, "VerifierToken address mismatch");
        require(address(treeNft.legacyToken()) == legacyTokenAddress, "LegacyToken address mismatch");

        CareToken careToken = CareToken(careTokenAddress);
        require(careToken.owner() == treeNftAddress, "CareToken ownership not transferred");

        console.log("Deployment verification passed.\n");
    }
}
