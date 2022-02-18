const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const GaugeFactory = await deployments.getArtifact(
    "srcBuild/Gauge.sol:GaugeFactory"
  );
  await deploy("GaugeFactory", {
    contract: GaugeFactory,
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv
};
module.exports.tags = ["Gauge", "GaugeFactory"];
