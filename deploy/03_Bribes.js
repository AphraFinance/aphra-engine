const { ethers } = require("hardhat");
const EMPTY = "0x0000000000000000000000000000000000000000";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const BribeFactory = await deployments.getArtifact(
    "srcBuild/Bribe.sol:BribeFactory"
  );
  const bribes = await deploy("BribeFactory", {
    contract: BribeFactory,
    from: deployer,
    log: true,
  });
};
module.exports.tags = ["Gauge", "GaugeFactory"];
