// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./SPULandNFT.sol";

import "hardhat/console.sol";

contract SPUMarket is Ownable, IERC721Receiver {
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    EnumerableMap.UintToAddressMap private lands;

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
        SPULandNFT nft = SPULandNFT(lands.get(rip_));
        return (lands.get(rip_), nft.dailyPrice(), nft.totalSupply());
    }

    function createLand(
        uint256 rip_,
        uint256 fractions_,
        uint256 dailyPrice_
    ) external onlyOwner {
        require(lands.contains(rip_) == false, "this rip already exists");

        // clone Land
        SPULandNFT landClone = SPULandNFT(Clones.clone(NFT_IMPLEMENTATION));
        landClone.initialize(rip_, fractions_, dailyPrice_);

        lands.set(rip_, address(landClone));

        emit LandCreated(rip_, address(landClone));
    }

    function rent(
        uint256 rip_,
        uint256 amount_,
        uint256 days_
    ) external payable {
        SPULandNFT nft = SPULandNFT(lands.get(rip_));

        require(
            amount_ * nft.dailyPrice() * days_ == msg.value,
            "incorrect value sent"
        );

        require(
            nft.leased(block.timestamp) + amount_ <= nft.totalSupply(),
            "amount exceed land size"
        );

        require(
            nft.leased(block.timestamp) < nft.totalSupply(),
            "all nfts are leased"
        );

        for (uint256 i = 0; i < nft.totalSupply(); i++) {
            if (nft.userExpires(i) < block.timestamp && amount_ > 0) {
                nft.setUser(
                    i,
                    _msgSender(),
                    uint64(block.timestamp + (days_ * ONE_DAY_IN_SEC))
                );
                amount_--;
                emit LandLeased(rip_, address(nft), _msgSender());
            }
        }
    }

    function leasedLandsByWallet(
        address wallet_
    ) external view returns (address[] memory) {
        address[] memory _leasedNfts = new address[](lands.length());
        // console.log("_leasedNfts length %s", _leasedNfts.length);
        for (uint256 rip_ = 0; rip_ < lands.length(); rip_++) {
            // console.log("_leasedNfts rip_ %s", rip_);
            (, address nftAddress) = lands.at(rip_);
            // console.log("_leasedNfts nftAddress %s", nftAddress);
            SPULandNFT nft = SPULandNFT(nftAddress);

            // console.log(
            //     "_leasedNfts leasedByWallet %s",
            //     nft.leasedByWallet(block.timestamp, wallet_)
            // );
            if (nft.leasedByWallet(block.timestamp, wallet_) > 0) {
                _leasedNfts[rip_] = nftAddress;
            }

            return _leasedNfts;
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
