const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer, empty } = await getNamedAccounts();
  await deploy("MultiRolesAuthority", {
    from: deployer,
    args: [deployer, empty],
    log: true,
  });
};
module.exports.tags = ["MultiRolesAuthority"];
