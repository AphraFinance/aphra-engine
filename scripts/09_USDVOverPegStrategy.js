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
  const { deployer, vader, weth, USDV3Crv, xvader, unirouter, guardian } =
    await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const vaderGateway = await deployments.get("VaderGateway");
  const avUSDVBribe = await deployments.get("avUSDVBribe");
  await deploy("USDVOverPegStrategy", {
    from: deployer,
    args: [
      vader,
      guardian,
      multiRolesAuthority.address,
      USDV3Crv,
      xvader,
      vaderGateway.address,
      unirouter,
      weth,
      avUSDVBribe.address,
    ],
    log: true,
  });
};
module.exports.tags = ["USDVOverPegStrategy"];
// module.exports.dependencies = ["MultiRolesAuthority"];
