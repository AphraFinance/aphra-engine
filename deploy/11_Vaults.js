const { ethers } = require("hardhat");
const {
  GOVERNANCE,
  VADER_ADDR,
  POOL,
  XVADER,
  UNIROUTER,
  WETH,
  ROLES,
} = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const multiRolesAuthorityDeployment = await deployments.get(
    "MultiRolesAuthority"
  );
  const MultiRolesAuthority = await deployments.getExtendedArtifact(
    "MultiRolesAuthority"
  );
  const vfArtifact = await deployments.getExtendedArtifact("VaultFactory");
  const vfDeployment = await deployments.get("VaultFactory");

  const erc20Artifact = await deployments.getArtifact("AphraToken");
  const vader = await ethers.getContractAtFromArtifact(
    erc20Artifact,
    VADER_ADDR
  );
  const VaultConfigurationModule = await deploy("VaultConfigurationModule", {
    from: deployer,
    args: [deployer, multiRolesAuthorityDeployment.address],
    log: true,
  });

  const VaultInitializationModule = await deploy("VaultInitializationModule", {
    from: deployer,
    args: [
      VaultConfigurationModule.address,
      deployer,
      multiRolesAuthorityDeployment.address,
    ],
    log: true,
  });

  const VaultConfigurationModuleContract =
    await ethers.getContractAtFromArtifact(
      VaultConfigurationModule,
      VaultConfigurationModule.address
    );

  await VaultConfigurationModuleContract.functions.setDefaultFeePercent(
    ethers.utils.parseEther("0.1", { from: deployer })
  );
  await VaultConfigurationModuleContract.functions.setDefaultHarvestDelay(
    21600,
    {
      from: deployer,
    }
  ); //6 hours
  await VaultConfigurationModuleContract.functions.setDefaultHarvestWindow(
    300,
    {
      from: deployer,
    }
  ); // 5 mins

  await VaultConfigurationModuleContract.functions.setDefaultTargetFloatPercent(
    ethers.utils.parseEther("0.01"),
    { from: deployer }
  );

  const VaultFactory = await ethers.getContractAtFromArtifact(
    vfArtifact,
    vfDeployment.address
  );

  const vaderVault = await VaultFactory.functions.deployVault(VADER_ADDR, {
    from: deployer,
  });

  const VaultInitializationModuleContract =
    await ethers.getContractAtFromArtifact(
      VaultInitializationModule,
      VaultInitializationModule.address
    );

  const vaderVaultAddress = await VaultFactory.functions.getVaultFromUnderlying(
    VADER_ADDR
  );

  const MultiRoleAuthority = await ethers.getContractAtFromArtifact(
    MultiRolesAuthority,
    multiRolesAuthorityDeployment.address
  );

  const Vault = await deployments.getExtendedArtifact("Vault");
  const VaultContract = await ethers.getContractAtFromArtifact(
    Vault,
    vaderVaultAddress[0]
  );
  const setFeeSig = VaultContract.interface.getSighash("setFeePercent");
  const setHarvestDelaySig =
    VaultContract.interface.getSighash("setHarvestDelay");
  const setHarvestWindowSig =
    VaultContract.interface.getSighash("setHarvestWindow");
  const setTargetFloatPercentSig = VaultContract.interface.getSighash(
    "setTargetFloatPercent"
  );
  // VAULT CONFIG module permissions
  await MultiRoleAuthority.functions.setUserRole(
    VaultConfigurationModule.address,
    ROLES.VAULT_CONFIG,
    true
  );

  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    setFeeSig,
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    setHarvestDelaySig,
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    setHarvestWindowSig,
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    setTargetFloatPercentSig,
    true
  );

  //vault init module permissions
  await MultiRoleAuthority.functions.setUserRole(
    VaultInitializationModule.address,
    ROLES.VAULT_INIT_MODULE,
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_INIT_MODULE,
    VaultContract.interface.getSighash("initialize"),
    true
  );
  const tx = await VaultInitializationModuleContract.functions.initializeVault(
    vaderVaultAddress[0]
  );

  console.log(await tx.wait());
};
module.exports.tags = ["VaderVault"];
module.exports.dependencies = ["VaultFactory"];
