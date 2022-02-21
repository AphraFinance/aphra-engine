const { USDV_ADDR, VADER_ADDR, ROLES, POOL } = require("../aphraAddressConfig");
const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read, save } = deployments;
  const { getContract } = ethers;

  const { deployer } = await getNamedAccounts();

  const USDVOverPegStrategy = await getContract("USDVOverPegStrategy");
  const VaderGateway = await getContract("VaderGateway");

  console.log("Setup Strategy User Role");
  //setup USDVOverPegStrategy role
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setUserRole",
    ...[USDVOverPegStrategy.address, ROLES.STRATEGY, true]
  );
  console.log("Setup Strategy role Capabilities VaderGateway partnerMint");
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[ROLES.STRATEGY, VaderGateway.interface.getSighash("partnerMint"), true]
  );
  console.log("Setup Strategy role Capabilities VaderGateway partnerBurn");
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setRoleCapability",
    ...[ROLES.STRATEGY, VaderGateway.interface.getSighash("partnerBurn"), true]
  );

  const avVADER = await getContract("avVADER");
  const avUSDV = await getContract("avUSDV");

  console.log("Setup Vault user role");
  //setup avVADER role
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setUserRole",
    ...[avVADER.address, ROLES.VAULT, true]
  );

  //setup avUSDV role
  await execute(
    // execute function call on contract
    "MultiRolesAuthority",
    { from: deployer, log: true },
    "setUserRole",
    ...[avUSDV.address, ROLES.VAULT, true]
  );
})();
