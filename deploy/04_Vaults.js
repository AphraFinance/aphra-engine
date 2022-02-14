const { ethers } = require("hardhat");
const EMPTY = "0x0000000000000000000000000000000000000000";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const vaultFactory = await deploy("VaultFactory", {
    from: deployer,
    args: [deployer, multiRolesAuthority.address],
    log: true,
  });
};
module.exports.tags = ["Vault", "VaultFactory"];
module.exports.dependencies = ["MultiRolesAuthority"];
