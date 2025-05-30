// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlanterToken is ERC20 {

    constructor(uint256 initialSupply) ERC20("PlanterToken", "PLT") {
    }
}
