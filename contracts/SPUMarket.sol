// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SPUMarket is Ownable {
    
    private uint256[] lands;


    constructor() {
        
    }

    function createLand(uint256 rip, uint8 fractions) onlyOwner {
        
    }
}