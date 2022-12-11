import { ethers, run } from "hardhat";

async function main() {
  const SPULandNFTFactory = await ethers.getContractFactory("SPULandNFT");
  const SPULandNFT = await SPULandNFTFactory.deploy();

  const SPUMarketFactory = await ethers.getContractFactory("SPUMarket");
  const SPUMarket = await SPUMarketFactory.deploy(SPULandNFT.address);

  console.log(`SPUMarket deployed to ${SPUMarket.address}`);

  // verify SarauMaker
  await run("verify:verify", {
    address: SPULandNFT.address,
  });

  // verify SarauNFT
  await run("verify:verify", {
    address: SPUMarket.address,
    constructorArguments: [SPULandNFT.address],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
