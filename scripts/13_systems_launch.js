const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { getContract } = ethers;
  const { execute, save } = deployments;
  const { deployer } = await getNamedAccounts();
  const Minter = await getContract("Minter");
  const Voter = await getContract("Voter");

  await execute(
    // execute function call on contract
    "AphraToken",
    { from: deployer, log: true },
    "setMinter",
    ...[Minter.address]
  );
  await execute(
    // execute function call on contract
    "veAPHRA",
    { from: deployer, log: true },
    "setVoter",
    ...[Voter.address]
  );
  await execute(
    // execute function call on contract
    "ve_dist",
    { from: deployer, log: true },
    "setDepositor",
    ...[Minter.address]
  );
  const avVADER = await deployments.get("avVADER");
  const avUSDV = await deployments.get("avUSDV");
  const avUSDV3Crv = await deployments.get("avUSDV3Crv");
  const initialAssets = [avVADER.address, avUSDV.address, avUSDV3Crv.address];
  await execute(
    // execute function call on contract
    "Voter",
    { from: deployer, log: true },
    "initialize",
    ...[initialAssets, Minter.address]
  );

  const avVADERGaugeTXN = await execute(
    // execute function call on contract
    "Voter",
    { from: deployer, log: true },
    "createGauge",
    ...[avVADER.address]
  );
  console.log(avVADERGaugeTXN);
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

  const avUSDVGaugeTxn = await execute(
    // execute function call on contract
    "Voter",
    { from: deployer, log: true },
    "createGauge",
    ...[avUSDV.address]
  );
  console.log(avUSDVGaugeTxn);

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

  const avUSDV3CrvGaugeTxn = await execute(
    // execute function call on contract
    "Voter",
    { from: deployer, log: true },
    "createGauge",
    ...[avUSDV3Crv.address]
  );
  console.log(avUSDV3CrvGaugeTxn);

  for (let log of avUSDV3CrvGaugeTxn.events) {
    if (log.event && log.event === "GaugeCreated") {
      const [gaugeAddress, creator, bribeAddress, asset] = log.args;

      const GaugeArtifact = await deployments.getArtifact("Gauge");
      const BribeArtifact = await deployments.getArtifact("Bribe");
      const avUSDV3CrvGauge = {
        abi: GaugeArtifact.abi,
        address: gaugeAddress,
        transactionHash: avUSDV3CrvGaugeTxn.transactionHash,
        receipt: avUSDV3CrvGaugeTxn,
      };
      await save("avUSDV3CrvGauge", avUSDV3CrvGauge);
      const avUSDV3CrvBribe = {
        abi: BribeArtifact.abi,
        address: bribeAddress,
        transactionHash: avUSDV3CrvGaugeTxn.transactionHash,
        receipt: avUSDV3CrvGaugeTxn,
      };
      await save("avUSDV3CrvBribe", avUSDV3CrvBribe);
    }
  }

  await execute(
    // execute function call on contract
    "Minter",
    { from: deployer, log: true },
    "initialize",
    ...[
      [], //veLock
      [], //veLockAmount
      [], //vesting lock
      [], //vesting amount
      ethers.BigNumber.from("100000000000000000000000000"),
    ]
  );
})();
