// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// Organisaiton Factory and Organisation
error TokenDoesNotExist();
error TreeAlreadyDead();
error NotTreeOwner();
error AlreadyVerified();

error NotOrganisationMember();
error NotOrganisationOwner();
error AlreadyOwner();
error OnlyOwner();

error InvalidApprovalStatusInput();
error InvalidDescriptionInput();
error InvalidOrganisationIdInput();
error NeedAnotherOwner();

/// Request
error InvalidRequestId();
error InvalidStatus();
error AlreadyProcessed();

/// Verification
error InvalidVerificationId();
error InvalidAddressInput();
error InvalidNameInput();

/// TreeNFT
error PaginationLimitExceeded();
error InvalidTreeID();
error MinimumMarkDeadTimeNotReached();

/// User
error UserAlreadyRegistered();
error UserNotRegistered();
