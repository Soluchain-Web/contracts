// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./SPULandNFT.sol";

contract SPUMarket is Ownable, IERC721Receiver {
    struct Land {
        address addr;
        uint256 dailyPrice;
        uint256 total;
        uint256 rented;
    }

    mapping(uint256 => Land) lands;

    address public immutable NFT_IMPLEMENTATION;

    event LandCreated(uint256 indexed rip, address indexed nft);

    constructor(address nftImplementation_) {
        NFT_IMPLEMENTATION = nftImplementation_;
    }

    function getLandDetail(uint256 rip_)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            lands[rip_].addr,
            lands[rip_].dailyPrice,
            lands[rip_].total,
            lands[rip_].rented
        );
    }

    function createLand(
        uint256 rip,
        uint256 fractions,
        uint256 dailyPrice
    ) external onlyOwner {
        require(lands[rip].total == 0, "this rip already exists");

        // clone Land
        SPULandNFT landClone = SPULandNFT(Clones.clone(NFT_IMPLEMENTATION));
        landClone.initialize(rip, fractions);

        lands[rip] = Land(address(landClone), dailyPrice, fractions, 0);

        emit LandCreated(rip, address(landClone));
    }

    function rent(
        uint256 rip_,
        uint256 amount_,
        uint256 days_
    ) external payable {
        require(
            lands[rip_].rented + amount_ <= lands[rip_].total,
            "amount exceed land size"
        );
        require(
            lands[rip_].dailyPrice * days_ == msg.value,
            "incorrect value sent"
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
