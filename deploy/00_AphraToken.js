const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("AphraToken", {
    from: deployer,
    log: true,
  });
};
module.exports.tags = ["AphraToken"];
