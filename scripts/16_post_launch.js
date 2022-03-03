const hre = require("hardhat");
const prompt = require("prompt-sync")();
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read } = deployments;
  const { deployer, guardian } = await getNamedAccounts();

  //transfer ownership to the multisig of everything
  console.log("Guardian Address: ", guardian);
  console.log(
    "AphraFinance.eth:",
    await ethers.provider.resolveName("aphrafinance.eth")
  );
  let answer = prompt("MultiRolesAuthority:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "MultiRolesAuthority",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("VaultFactory:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "VaultFactory",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("AirdropClaim:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "AirdropClaim",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("VaderGateway:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "VaderGateway",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("avUSDV:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "avUSDV",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("avVADER:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "avVADER",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("avUSDV3CRV:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "avUSDV3CRV",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("VaultConfigurationModule:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "VaultConfigurationModule",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("VaultInitializationModule:setOwner(guardian): (y/n/exit) ");

  if (answer === "y") {
    const tx = await execute(
      // execute function call on contract
      "VaultInitializationModule",
      { from: deployer, log: true },
      "setOwner",
      ...[guardian]
    );

    console.log("Done", tx);
    console.log("Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
  //setup vault to trust the strategy, deposit into it some amount, and then setup a withdrawal into the strategy
})();
