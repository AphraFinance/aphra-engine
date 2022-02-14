const { ethers } = require("hardhat");
const { GOVERNANCE } = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ve = await deployments.get("veAPHRA");
  const ve_dist = await deployments.get("ve_dist");
  const voter = await deployments.get("Voter");
  const minter = await deploy("Minter", {
    from: deployer,
    args: [voter.address, ve.address, ve_dist.address],
    log: true,
  });
};
module.exports.tags = ["Minter"];
module.exports.depedencies = ["veAPHRA", "ve_dist", "Voter"];
