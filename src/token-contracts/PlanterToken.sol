// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlanterToken is ERC20, Ownable {
    constructor(address owner) Ownable(owner) ERC20("PlanterToken", "PRT") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
