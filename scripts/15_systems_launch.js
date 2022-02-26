const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
const prompt = require("prompt-sync")();
(async () => {
  const { execute, read } = deployments;
  const {
    deployer,
    guardian,
    androolloyd,
    tekka,
    ehjc,
    rohmanus,
    greenbergz,
    grutte,
  } = await getNamedAccounts();

  const Minter = await ethers.getContract("Minter");
  const AirdropClaim = await ethers.getContract("AirdropClaim");

  //22 M for the dao treasury + 8.5M for the future team, guarded by the multisig, 30.5M
  //30.5M, 3m for airdrop, 6.5M for current team //
  //39.5M total

  const DAO_ALLOC = ethers.utils.parseEther("30500000"); //30.5M
  const AIRDROP_ALLOC = ethers.utils.parseEther("3000000"); //3M
  const FOUNDER_ALLOC = ethers.utils.parseEther("2000000"); //2M
  const EARLY_TEAM_ALLOC = ethers.utils.parseEther("1000000"); //1M
  const TEAM_ALLOC = ethers.utils.parseEther("500000"); //500k

  const veLockReceivers = [
    androolloyd,
    tekka,
    ehjc,
    rohmanus,
    greenbergz,
    grutte,
  ];

  const veLockAmounts = [
    FOUNDER_ALLOC, //2M
    EARLY_TEAM_ALLOC, // 1
    EARLY_TEAM_ALLOC, // 1
    EARLY_TEAM_ALLOC, // 1
    EARLY_TEAM_ALLOC, // 1
    TEAM_ALLOC, // 0.5
  ];

  const rawLockReceivers = [guardian, AirdropClaim.address];
  const rawLockAmounts = [DAO_ALLOC, AIRDROP_ALLOC];

  const maxInitialMint = ethers.utils.parseEther("40000000"); //40M

  let answer = prompt("Execute AphraToken setMinter: (y/n/exit) ");

  if (answer === "y") {
    await execute(
      // execute function call on contract
      "AphraToken",
      { from: deployer, log: true },
      "setMinter",
      ...[Minter.address]
    );
  } else if (answer === "exit") {
    process.exit(1);
  }

  answer = prompt("Execute Minter initialize: (y/n/exit) ");

  if (answer === "y") {
    console.log("Initializing Minter");

    await execute(
      // execute function call on contract
      "Minter",
      { from: deployer, log: true },
      "initialize",
      ...[
        veLockReceivers, //receivers
        veLockAmounts, //base aphra locked
        rawLockReceivers, //raw aphra addrs
        rawLockAmounts, //raw aphra moved
        maxInitialMint,
      ]
    );
    console.log("Initializing Minter: Done");
  } else if (answer === "exit") {
    process.exit(1);
  }
})();
