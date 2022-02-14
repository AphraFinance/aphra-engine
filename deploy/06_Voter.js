const { ethers } = require("hardhat");
const { GOVERNANCE } = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const gauges = await deployments.get("GaugeFactory");
  const bribes = await deployments.get("BribeFactory");
  const ve = await deployments.get("veAPHRA");

  const Voter = await deployments.getArtifact("srcBuild/Voter.sol:Voter");
  const voter = await deploy("Voter", {
    contract: Voter,
    from: deployer,
    args: [
      GOVERNANCE,
      multiRolesAuthority.address,
      ve.address,
      gauges.address,
      bribes.address,
    ],
    log: true,
  });
};
module.exports.tags = ["Voter"];
module.exports.depedencies = [
  "GaugeFactory",
  "BribeFactory",
  "veAPHRA",
  "MultiRolesAuthority",
];
