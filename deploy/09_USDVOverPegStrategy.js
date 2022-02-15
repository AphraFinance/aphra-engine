const { ethers } = require("hardhat");
const {
  GOVERNANCE,
  VADER_ADDR,
  POOL,
  XVADER,
  UNIROUTER,
  WETH,
} = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const vaderGateway = await deployments.get("VaderGateway");
  await deploy("USDVOverPegStrategy", {
    from: deployer,
    args: [
      VADER_ADDR,
      GOVERNANCE,
      multiRolesAuthority.address,
      POOL,
      XVADER,
      vaderGateway.address,
      UNIROUTER,
      WETH,
    ],
    log: true,
  });
};
module.exports.tags = ["USDVOverPegStrategy"];
module.exports.dependencies = ["VaderGateway", "MultiRolesAuthority"];
