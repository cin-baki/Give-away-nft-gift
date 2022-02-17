const { ethers, upgrades } = require('hardhat');

async function main() {
	const SipherStatueFactory = await ethers.getContractFactory('SipherStatue');
    SipherStatue = await SipherStatueFactory.deploy();
    console.log("Deploying ... ")
	console.log("SipherStatue deployed to:", SipherStatue.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
