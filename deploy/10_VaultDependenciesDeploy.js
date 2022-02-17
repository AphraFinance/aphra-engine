const { ethers } = require("hardhat");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const MultiRolesAuthority = await ethers.getContract("MultiRolesAuthority");

  await deploy("VaultFactory", {
    from: deployer,
    args: [deployer, MultiRolesAuthority.address],
    log: true,
  });

  const VaultConfigurationModule = await deploy("VaultConfigurationModule", {
    from: deployer,
    args: [deployer, MultiRolesAuthority.address],
    log: true,
  });

  await deploy("VaultInitializationModule", {
    from: deployer,
    args: [
      VaultConfigurationModule.address,
      deployer,
      MultiRolesAuthority.address,
    ],
    log: true,
  });
};
module.exports.tags = [
  "VaultFactory",
  "VaultConfigurationModule",
  "VaultInitializationModule",
];
module.exports.dependencies = ["MultiRolesAuthority"];
