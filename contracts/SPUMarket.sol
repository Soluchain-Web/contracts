// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SPUMarket is Ownable {
    struct Land {
        address addr;
        uint256 total;
        uint256 rented;
    }

    mapping (uint256 => Land) name;


    constructor() {
        
    }

    function createLand(uint256 rip, uint8 fractions) onlyOwner {
        require(lands[rip].total == 0, "this rip alreay exists");

        lands[rip] = Land();
    }

    function rent(uint256 rip, uint256 amount) payable returns () {
        require(lands[rip].available + amount <= lands[rip].total, "amount exceed land size");
    }
}