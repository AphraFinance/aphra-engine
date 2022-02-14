const { ethers } = require("hardhat");
const {
  GOVERNANCE,
  VADER_ADDR,
  VADER_MINTER,
  USDV_ADDR,
  UNIROUTER,
  WETH,
} = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const vaderGateway = await deploy("VaderGateway", {
    from: deployer,
    args: [
      VADER_MINTER,
      GOVERNANCE,
      multiRolesAuthority.address,
      VADER_ADDR,
      USDV_ADDR,
    ],
  });
};
module.exports.tags = ["VaderGateway"];
module.exports.dependencies = ["MultiRolesAuthority"];
