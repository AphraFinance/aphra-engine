const { ROLES } = require("../aphraAddressConfig");
const prompt = require("prompt-sync")();
const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute } = deployments;
  const { getContract } = ethers;

  const { deployer } = await getNamedAccounts();

  const USDVOverPegStrategy = await getContract("USDVOverPegStrategy");
  const VaderGateway = await getContract("VaderGateway");

  let answer = prompt("Execute Setup Strategy User Role (y/n/exit) : ");
  //setup USDVOverPegStrategy role

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { nonce: 32, from: deployer, log: true },
      "setUserRole",
      ...[USDVOverPegStrategy.address, ROLES.STRATEGY, true]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt(
    "Execute Strategy role Capabilities VaderGateway partnerMint (y/n/exit) : "
  );

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setRoleCapability",
      ...[
        ROLES.STRATEGY,
        VaderGateway.interface.getSighash("partnerMint"),
        true,
      ]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt(
    "Execute Setup Strategy role Capabilities VaderGateway partnerBurn (y/n/exit) : "
  );

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setRoleCapability",
      ...[
        ROLES.STRATEGY,
        VaderGateway.interface.getSighash("partnerBurn"),
        true,
      ]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Setup Setup avVader Vault user role (y/n/exit) : ");

  if (answer === "y") {
    const avVADER = await getContract("avVADER");

    //setup avVADER role
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setUserRole",
      ...[avVADER.address, ROLES.VAULT, true]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Setup Setup avUSDV Vault user role (y/n/exit) : ");
  if (answer === "y") {
    const avUSDV = await getContract("avUSDV");

    //setup avUSDV role
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setUserRole",
      ...[avUSDV.address, ROLES.VAULT, true]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt(
    "Execute Vault role Capabilities Strategy mint (y/n/exit) : "
  );

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setRoleCapability",
      ...[ROLES.VAULT, USDVOverPegStrategy.interface.getSighash("mint"), true]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }
})();
