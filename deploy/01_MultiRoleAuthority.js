const { ethers } = require("hardhat");
const EMPTY = "0x0000000000000000000000000000000000000000";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("MultiRolesAuthority", {
    from: deployer,
    args: [deployer, EMPTY],
    log: true,
  });
};
module.exports.tags = ["MultiRolesAuthority"];
