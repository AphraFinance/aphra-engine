const hre = require("hardhat");
const prompt = require("prompt-sync")();
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { getContract } = ethers;
  const { execute, save } = deployments;
  const { deployer, USDV3Crv } = await getNamedAccounts();
  const Minter = await getContract("Minter");

  let answer = prompt("Execute veAPHRA setDepositor: (y/n/exit) ");

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "ve_dist",
      { from: deployer, log: true },
      "setDepositor",
      ...[Minter.address]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }
  answer = prompt("Execute veAPHRA setVoter: (y/n/exit) ");

  if (answer === "y") {
    const Voter = await getContract("Voter");

    await execute(
      // execute function call on contract
      "veAPHRA",
      { from: deployer, log: true },
      "setVoter",
      ...[Voter.address]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  const avVADER = await deployments.get("avVADER");
  const avUSDV = await deployments.get("avUSDV");
  const initialAssets = [avVADER.address, avUSDV.address, USDV3Crv];
  answer = prompt("Execute Voter initialize: (y/n/exit) ");

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "Voter",
      { from: deployer, log: true },
      "initialize",
      ...[initialAssets, Minter.address]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Create avVADER Gauge/Bribe: (y/n/exit) ");

  if (answer === "y") {
    const avVADERGaugeTXN = await execute(
      // execute function call on contract
      "Voter",
      { from: deployer, log: true },
      "createGauge",
      ...[avVADER.address]
    );
    for (let log of avVADERGaugeTXN.events) {
      if (log.event && log.event === "GaugeCreated") {
        const [gaugeAddress, creator, bribeAddress, asset] = log.args;

        const GaugeArtifact = await deployments.getArtifact("Gauge");
        const BribeArtifact = await deployments.getArtifact("Bribe");
        const gauge = {
          abi: GaugeArtifact.abi,
          address: gaugeAddress,
          transactionHash: avVADERGaugeTXN.transactionHash,
          receipt: avVADERGaugeTXN,
        };
        await save("avVADERGauge", gauge);
        const bribe = {
          abi: BribeArtifact.abi,
          address: bribeAddress,
          transactionHash: avVADERGaugeTXN.transactionHash,
          receipt: avVADERGaugeTXN,
        };
        await save("avVADERBribe", bribe);
      }
    }
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Create avUSDV Gauge/Bribe: (y/n/exit) ");

  if (answer === "y") {
    const avUSDVGaugeTxn = await execute(
      // execute function call on contract
      "Voter",
      { from: deployer, log: true },
      "createGauge",
      ...[avUSDV.address]
    );
    console.log("Create avUSDV Gauge/Bribe", avUSDVGaugeTxn);

    for (let log of avUSDVGaugeTxn.events) {
      if (log.event && log.event === "GaugeCreated") {
        const [gaugeAddress, creator, bribeAddress, asset] = log.args;

        const GaugeArtifact = await deployments.getArtifact("Gauge");
        const BribeArtifact = await deployments.getArtifact("Bribe");
        const gauge = {
          abi: GaugeArtifact.abi,
          address: gaugeAddress,
          transactionHash: avUSDVGaugeTxn.transactionHash,
          receipt: avUSDVGaugeTxn,
        };
        await save("avUSDVGauge", gauge);
        const bribe = {
          abi: BribeArtifact.abi,
          address: bribeAddress,
          transactionHash: avUSDVGaugeTxn.transactionHash,
          receipt: avUSDVGaugeTxn,
        };
        await save("avUSDVBribe", bribe);
      }
    }
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Create USDV3CRV Gauge/Bribe: (y/n/exit) ");

  if (answer === "y") {
    const USDV3CrvGaugeTxn = await execute(
      // execute function call on contract
      "Voter",
      { from: deployer, log: true },
      "createGauge",
      ...[USDV3Crv]
    );

    for (let log of USDV3CrvGaugeTxn.events) {
      if (log.event && log.event === "GaugeCreated") {
        const [gaugeAddress, creator, bribeAddress, asset] = log.args;

        const GaugeArtifact = await deployments.getArtifact("Gauge");
        const BribeArtifact = await deployments.getArtifact("Bribe");
        const gauge = {
          abi: GaugeArtifact.abi,
          address: gaugeAddress,
          transactionHash: USDV3CrvGaugeTxn.transactionHash,
          receipt: USDV3CrvGaugeTxn,
        };
        await save("USDV3CrvGauge", gauge);
        const bribe = {
          abi: BribeArtifact.abi,
          address: bribeAddress,
          transactionHash: USDV3CrvGaugeTxn.transactionHash,
          receipt: USDV3CrvGaugeTxn,
        };
        await save("USDV3CrvBribe", bribe);
      }
    }
  } else if (answer === "exit") {
    process.exit(1);
  }
})();
