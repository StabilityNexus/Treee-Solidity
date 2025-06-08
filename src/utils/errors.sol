// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// Organisaiton Factory and Organisation

error InvalidOrganisationId();
error OrganisationDoesNotExist();

error TokenDoesNotExist();
error TreeAlreadyDead();
error NotTreeOwner();
error AlreadyVerified();

error NotOrganisationMember();
error NotOrganisationOwner();
error AlreadyOwner();
error AlreadyMember();
error OnlyOwner();
error InvalidOrganisation();

error InvalidApprovalStatusInput();
error InvalidDescriptionInput();
error InvalidOrganisationIdInput();
error NeedAnotherOwner();

error InvalidProposalId();
error AlreadyVoted();
error InvalidInput();
error PaginationLimitExceeded();
error InvalidContractAddress();

/// Request
error InvalidRequestId();
error InvalidStatus();
error AlreadyProcessed();

/// Verification
error InvalidVerificationId();
error InvalidAddressInput();
error InvalidNameInput();

/// TreeNFT
error InvalidTreeID();
error MinimumMarkDeadTimeNotReached();
error InvalidCoordinates();

/// User
error UserAlreadyRegistered();
error UserNotRegistered();

/// Deploy

error OwnershipNotTransferred();
