const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read } = deployments;
  const { deployer } = await getNamedAccounts();

  //setup vault to trust the strategy, deposit into it some amount, and then setup a withdrawal into the strategy
})();
