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
    }

    mapping(uint256 => Land) lands;

    // mapping(uint256 => Land) lands;

    uint64 constant ONE_DAY_IN_SEC = 60 * 60 * 24;

    address public immutable NFT_IMPLEMENTATION;

    event LandCreated(uint256 indexed rip, address indexed nft);
    event LandLeased(
        uint256 indexed rip,
        address indexed nft,
        address indexed wallet
    );

    constructor(address nftImplementation_) {
        NFT_IMPLEMENTATION = nftImplementation_;
    }

    function getLandDetail(
        uint256 rip_
    ) external view returns (address, uint256, uint256) {
        return (lands[rip_].addr, lands[rip_].dailyPrice, lands[rip_].total);
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

        lands[rip] = Land(address(landClone), dailyPrice, fractions);

        emit LandCreated(rip, address(landClone));
    }

    function rent(
        uint256 rip_,
        uint256 amount_,
        uint256 days_
    ) external payable {
        require(
            amount_ * lands[rip_].dailyPrice * days_ == msg.value,
            "incorrect value sent"
        );

        SPULandNFT nft = SPULandNFT(lands[rip_].addr);

        require(
            nft.leased(block.timestamp) + amount_ <= lands[rip_].total,
            "amount exceed land size"
        );

        require(
            nft.leased(block.timestamp) < nft.totalSupply(),
            "all nfts are leased"
        );

        for (uint256 i = 0; i < lands[rip_].total; i++) {
            if (nft.userExpires(i) < block.timestamp && amount_ > 0) {
                nft.setUser(
                    i,
                    _msgSender(),
                    uint64(block.timestamp + (days_ * ONE_DAY_IN_SEC))
                );
                amount_--;
                emit LandLeased(rip_, lands[rip_].addr, _msgSender());
            }
        }
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
