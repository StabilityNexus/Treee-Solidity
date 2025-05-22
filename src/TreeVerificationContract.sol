// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./utils/structs.sol";
import "./utils/errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TreeVerificationContract {
    mapping (uint256 => Verification) private s_verificationIDtoVerification;
    mapping (address => Verification[]) private s_userAddressToVerifications;
}