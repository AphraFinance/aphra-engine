const { USDV_ADDR, VADER_ADDR, ROLES, POOL } = require("../aphraAddressConfig");
const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read, save } = deployments;
  const { getContract } = ethers;

  const DEFAULT_FEE = "0.8";
  const { deployer } = await getNamedAccounts();
  console.log("setDefaultFeePercent");
  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultFeePercent",
    ...[ethers.utils.parseEther(DEFAULT_FEE)]
  );
  console.log("setDefaultHarvestDelay");

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestDelay",
    ...[21600] // 6 hour
  );
  console.log("setDefaultHarvestWindow");

  await execute(
    // execute function call on contract
    "VaultConfigurationModule",
    { from: deployer, log: true },
    "setDefaultHarvestWindow",
    ...[300] // 5 mins
  );
  console.log("setDefaultTargetFloatPercent");

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
  console.log("Deploy VADER Vault", avVaderTxnReceipt);
  const avUSDVTxnReceipt = await execute(
    // execute function call on contract
    "VaultFactory",
    { from: deployer, log: true },
    "deployVault",
    ...[USDV_ADDR]
  );
  console.log("Deploy USDV Vault", avUSDVTxnReceipt);

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
  // const USDV3crvVaultAddress = await read(
  //   "VaultFactory",
  //   { from: deployer, log: true },
  //   "getVaultFromUnderlying",
  //   ...[POOL]
  // );

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
  //
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
  console.log("MultiRolesAuthority setUserRole VAULT_INIT_MODULE");

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
  console.log(
    "MultiRolesAuthority setRoleCapability VAULT_INIT_MODULE initialize"
  );

  await execute(
    // execute function call on contract
    "VaultInitializationModule",
    { from: deployer, log: true },
    "initializeVault",
    ...[avVaderAddress]
  );
  console.log("avVADER Vault Initialized");

  await execute(
    // execute function call on contract
    "VaultInitializationModule",
    { from: deployer, log: true },
    "initializeVault",
    ...[USDVVaultAddress]
  );
  console.log("avUSDV Vault Initialized");

  // await execute(
  //   // execute function call on contract
  //   "VaultInitializationModule",
  //   { from: deployer, log: true },
  //   "initializeVault",
  //   ...[USDV3crvVaultAddress]
  // );
})();
