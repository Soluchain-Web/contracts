import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const RIP = 2022,
  FRACTIONS = 50,
  PRICE = (0.1 * 1e18).toString(),
  ONE_DAY_SEC = 60 * 60 * 24;

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

      expect(await SPUMarket.createLand(RIP, FRACTIONS, PRICE)).to.emit(
        SPUMarket,
        "LandCreated"
      );

      const landDetail = await SPUMarket.getLandDetail(RIP);

      expect(landDetail[1]).to.equal(PRICE);
      expect(landDetail[2]).to.equal(FRACTIONS);

      const nft = SPULandNFT.attach(landDetail[0]);

      expect(await nft.leased(await time.latest())).to.equal(0);

      expect(await nft.totalSupply()).to.equal(FRACTIONS);
    });
  });

  describe("User", function () {
    it("Should rent a land", async function () {
      const { SPUMarket, SPULandNFT, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );

      await SPUMarket.createLand(RIP, FRACTIONS, PRICE);

      const amountToRent = 3;
      const daysToRent = 2;

      const priceForDesiredAmountAndDays = ethers.BigNumber.from(amountToRent)
        .mul(daysToRent)
        .mul(PRICE);

      await SPUMarket.connect(otherAccount).rent(
        RIP,
        amountToRent,
        daysToRent,
        {
          value: priceForDesiredAmountAndDays,
        }
      );

      const landDetail = await SPUMarket.getLandDetail(RIP);

      const nft = SPULandNFT.attach(landDetail[0]);

      expect(await nft.leased(await time.latest())).to.equal(amountToRent);

      const leasedNfts = await SPUMarket.leasedLandsByWallet(
        otherAccount.address
      );

      expect(leasedNfts.length).to.equal(1);
    });

    it("Should expire a leased land", async function () {
      const { SPUMarket, SPULandNFT, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );

      await SPUMarket.createLand(RIP, FRACTIONS, PRICE);

      const amountToRent = 7;
      const daysToRent = 3;

      const priceForDesiredAmountAndDays = ethers.BigNumber.from(amountToRent)
        .mul(daysToRent)
        .mul(PRICE);

      await SPUMarket.connect(otherAccount).rent(
        RIP,
        amountToRent,
        daysToRent,
        {
          value: priceForDesiredAmountAndDays,
        }
      );

      const landDetail = await SPUMarket.getLandDetail(RIP);

      const nft = SPULandNFT.attach(landDetail[0]);

      // before time passes the user has the leased nfts
      expect(await nft.leased(await time.latest())).to.equal(amountToRent);

      const lastTime = await time.latest();
      // expiration time plus 1 second after
      await time.increaseTo(lastTime + ONE_DAY_SEC * daysToRent + 1);

      // after the time has passed, the user no longer has any leased nft
      expect(await nft.leased(await time.latest())).to.equal(0);
    });
  });
});
