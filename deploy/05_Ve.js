const { ethers } = require("hardhat");
const { GOVERNANCE } = require("../aphraAddressConfig");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const token = await deployments.get("AphraToken");
  const ve = await deploy("veAPHRA", {
    args: [token.address, GOVERNANCE, multiRolesAuthority.address],
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv
  const Ve_dist = await deployments.getArtifact("srcBuild/ve_dist.sol:ve_dist");

  const ve_dist = await deploy("ve_dist", {
    contract: Ve_dist,
    from: deployer,
    args: [ve.address],
    log: true,
  });
};
module.exports.tags = ["veAPHRA", "ve_dist"];
module.exports.dependencies = ["AphraToken", "MultiRolesAuthority"];
