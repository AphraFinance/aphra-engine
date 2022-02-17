const { USDV_ADDR, VADER_ADDR, ROLES, POOL } = require("../aphraAddressConfig");
const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read, save } = deployments;
  const { getContract } = ethers;

  const { deployer } = await getNamedAccounts();
  console.log("setDefaultFeePercent");
  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultFeePercent",
    ...[ethers.utils.parseEther("0.1")]
  );
  console.log("setDefaultHarvestDelay");

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestDelay",
    ...[21600]
  );
  console.log("setDefaultHarvestWindow");

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestWindow",
    ...[300]
  );
  console.log("setDefaultTargetFloatPercent");

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultTargetFloatPercent",
    ...[ethers.utils.parseEther("0.01")]
  );
  console.log("deployVault");

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

  //setup gauges

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
  await save("avVADER", avVaderDeployment);

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
  await save("avUSDV3Crv", avUSDV3CRVDeployment);
  // VAULT CONFIG module permissions

  const VaultConfigurationModule = await getContract(
    "VaultConfigurationModule"
  );
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

  const VaultInitializationModule = await getContract(
    "VaultInitializationModule"
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
})();
