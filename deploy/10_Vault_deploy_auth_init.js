const { ethers } = require("hardhat");
const { USDV_ADDR, VADER_ADDR, ROLES, POOL } = require("../aphraAddressConfig");
const { chalk } = require("chalk");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, execute, read, save } = deployments;
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

  const VaultInitializationModule = await deploy("VaultInitializationModule", {
    from: deployer,
    args: [
      VaultConfigurationModule.address,
      deployer,
      MultiRolesAuthority.address,
    ],
    log: true,
  });
  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultFeePercent",
    ...[ethers.utils.parseEther("0.1")]
  );
  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestDelay",
    ...[21600]
  );
  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestWindow",
    ...[300]
  );

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultTargetFloatPercent",
    ...[ethers.utils.parseEther("0.01")]
  );
  const avVaderTxnReceipt = await execute(
    // execute function call on contract
    "VaultFactory",
    { from: deployer, log: true },
    "deployVault",
    ...[VADER_ADDR]
  );

  const avUSDVTxnReceipt = await execute(
    // execute function call on contract
    "VaultFactory",
    { from: deployer, log: true },
    "deployVault",
    ...[USDV_ADDR]
  );

  const avUSDV3crvTxnReceipt = await execute(
    // execute function call on contract
    "VaultFactory",
    { from: deployer, log: true },
    "deployVault",
    ...[POOL]
  );

  const avVaderAddress = await read(
    "VaultFactory",
    { from: deployer, log: true },
    "getVaultFromUnderlying",
    ...[VADER_ADDR]
  );

  const USDVVaultAddress = await read(
    "VaultFactory",
    { from: deployer, log: true },
    "getVaultFromUnderlying",
    ...[USDV_ADDR]
  );
  const USDV3crvVaultAddress = await read(
    "VaultFactory",
    { from: deployer, log: true },
    "getVaultFromUnderlying",
    ...[POOL]
  );
  const VaultArtifact = await deployments.getArtifact("Vault");
  const AphraVaultContract = await ethers.getContractAt(
    "Vault",
    avVaderAddress
  );
  const avVaderDeployment = {
    abi: VaultArtifact.abi,
    address: avVaderAddress,
    transactionHash: avVaderTxnReceipt.transactionHash,
    receipt: avVaderTxnReceipt,
  };
  await save("avVader", avVaderDeployment);

  const avUSDVDeployment = {
    abi: VaultArtifact.abi,
    address: USDVVaultAddress,
    transactionHash: avUSDVTxnReceipt.transactionHash,
    receipt: avUSDVTxnReceipt,
  };
  await save("avUSDV", avUSDVDeployment);

  const avUSDV3CRVDeployment = {
    abi: VaultArtifact.abi,
    address: USDV3crvVaultAddress,
    transactionHash: avUSDV3crvTxnReceipt.transactionHash,
    receipt: avUSDV3crvTxnReceipt,
  };
  await save("avUSDV3CRV", avUSDV3CRVDeployment);
  // VAULT CONFIG module permissions

  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setUserRole",
    ...[VaultConfigurationModule.address, ROLES.VAULT_CONFIG, true]
  );
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[
      ROLES.VAULT_CONFIG,
      AphraVaultContract.interface.getSighash("setFeePercent"),
      true,
    ]
  );
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[
      ROLES.VAULT_CONFIG,
      AphraVaultContract.interface.getSighash("setHarvestDelay"),
      true,
    ]
  );
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[
      ROLES.VAULT_CONFIG,
      AphraVaultContract.interface.getSighash("setHarvestWindow"),
      true,
    ]
  );

  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[
      ROLES.VAULT_CONFIG,
      AphraVaultContract.interface.getSighash("setTargetFloatPercent"),
      true,
    ]
  );

  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setUserRole",
    ...[VaultInitializationModule.address, ROLES.VAULT_INIT_MODULE, true]
  );

  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[
      ROLES.VAULT_INIT_MODULE,
      AphraVaultContract.interface.getSighash("initialize"),
      true,
    ]
  );

  // console.log("📜 " + chalk.magenta("Vader Vault Initialized"));

  await execute(
    // execute function call on contract
    "VaultInitializationModule",
    { from: deployer, log: true },
    "initializeVault",
    ...[avVaderAddress]
  );
  await execute(
    // execute function call on contract
    "VaultInitializationModule",
    { from: deployer, log: true },
    "initializeVault",
    ...[USDVVaultAddress]
  );

  await execute(
    // execute function call on contract
    "VaultInitializationModule",
    { from: deployer, log: true },
    "initializeVault",
    ...[USDV3crvVaultAddress]
  );
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
module.exports.dependencies = ["MultiRolesAuthority"];
