import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const RIP = 2022,
  FRACTIONS = 500,
  PRICE = (0.1 * 1e18).toString();

describe("SPUMarket", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const SPULandNFTFactory = await ethers.getContractFactory("SPULandNFT");
    const SPULandNFT = await SPULandNFTFactory.deploy();

    const SPUMarketFactory = await ethers.getContractFactory("SPUMarket");
    const SPUMarket = await SPUMarketFactory.deploy(SPULandNFT.address);

    return { SPUMarket, SPULandNFT, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right SPULandNFT address", async function () {
      const { SPUMarket, SPULandNFT } = await loadFixture(
        deployOneYearLockFixture
      );

      expect(await SPUMarket.NFT_IMPLEMENTATION()).to.equal(SPULandNFT.address);
    });
  });

  describe("Owner", function () {
    it("Should create new land", async function () {
      const { SPUMarket, SPULandNFT } = await loadFixture(
        deployOneYearLockFixture
      );

      expect(
        await SPUMarket.createLand(
          RIP,
          FRACTIONS,
          PRICE,
        )
      ).to.emit(SPUMarket, "LandCreated");
    });
  });
});
