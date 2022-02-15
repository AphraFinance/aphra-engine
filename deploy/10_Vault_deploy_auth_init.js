const { ethers } = require("hardhat");
const { USDV_ADDR, VADER_ADDR, ROLES, POOL } = require("../aphraAddressConfig");
const { chalk } = require("chalk");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const MultiRoleAuthority = await ethers.getContract("MultiRolesAuthority");

  await deploy("VaultFactory", {
    from: deployer,
    args: [deployer, MultiRoleAuthority.address],
    log: true,
  });

  const VaultConfigurationModule = await deploy("VaultConfigurationModule", {
    from: deployer,
    args: [deployer, MultiRoleAuthority.address],
    log: true,
  });

  const VaultInitializationModule = await deploy("VaultInitializationModule", {
    from: deployer,
    args: [
      VaultConfigurationModule.address,
      deployer,
      MultiRoleAuthority.address,
    ],
    log: true,
  });

  const VaultConfigurationModuleContract = await ethers.getContract(
    "VaultConfigurationModule"
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

  const VaultFactory = await ethers.getContract("VaultFactory");

  //deploy a vader vault
  const vaderVaultDeployTx = await VaultFactory.functions.deployVault(
    VADER_ADDR,
    {
      from: deployer,
    }
  );
  console.log(await vaderVaultDeployTx.wait());
  const usdvVaultDeployTx = await VaultFactory.functions.deployVault(
    USDV_ADDR,
    {
      from: deployer,
    }
  );
  console.log(await usdvVaultDeployTx.wait());
  const usdv3CrvVaultTx = await VaultFactory.functions.deployVault(POOL, {
    from: deployer,
  });
  console.log(await usdv3CrvVaultTx.wait());

  const VaultInitializationModuleContract = await ethers.getContract(
    "VaultInitializationModule"
  );

  const vaderVaultAddress = await VaultFactory.functions.getVaultFromUnderlying(
    VADER_ADDR
  );
  const USDVVaultAddress = await VaultFactory.functions.getVaultFromUnderlying(
    USDV_ADDR
  );
  const USDV3crvVaultAddress =
    await VaultFactory.functions.getVaultFromUnderlying(POOL);

  const VaderVaultContract = await ethers.getContractAt(
    "Vault",
    vaderVaultAddress[0]
  );
  // VAULT CONFIG module permissions
  await MultiRoleAuthority.functions.setUserRole(
    VaultConfigurationModule.address,
    ROLES.VAULT_CONFIG,
    true
  );

  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    VaderVaultContract.interface.getSighash("setFeePercent"),
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    VaderVaultContract.interface.getSighash("setHarvestDelay"),
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    VaderVaultContract.interface.getSighash("setHarvestWindow"),
    true
  );
  await MultiRoleAuthority.functions.setRoleCapability(
    ROLES.VAULT_CONFIG,
    VaderVaultContract.interface.getSighash("setTargetFloatPercent"),
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
    VaderVaultContract.interface.getSighash("initialize"),
    true
  );
  // console.log("📜 " + chalk.magenta("Vader Vault Initialized"));
  const txn_avVADER =
    await VaultInitializationModuleContract.functions.initializeVault(
      vaderVaultAddress[0]
    );
  console.log("avVADER", await txn_avVADER.wait());

  // console.log("📜: " + chalk.magenta("USDV Vault Initialized"));
  const txn_avUSDV =
    await VaultInitializationModuleContract.functions.initializeVault(
      USDVVaultAddress[0]
    );
  console.log("avUSDV", await txn_avUSDV.wait());
  // console.log("📜  " + chalk.magenta("USDV 3Crv Vault Initialized"));
  const txn_avUSDV3crv =
    await VaultInitializationModuleContract.functions.initializeVault(
      USDV3crvVaultAddress[0]
    );

  console.log("avUSDV3Crv", await txn_avUSDV3crv.wait());
};
module.exports.tags = [
  "Vault",
  "VaultFactory",
  "VaultConfigurationModule",
  "VaultInitializationModule",
  "avVader",
  "avUSDV",
  "avUSDV3Crv",
];
module.exports.dependencies = ["MultiRoleAuthority"];
