const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
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

  const AirdropClaim = await ethers.getContract("AirdropClaim");

  const DAO_ALLOC = ethers.utils.parseEther("38500000"); //30M
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
    FOUNDER_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    TEAM_ALLOC,
  ];

  const rawLockReceivers = [guardian, AirdropClaim.address];
  const rawLockAmounts = [DAO_ALLOC, AIRDROP_ALLOC];

  //TODO: future team allocation has to be minted tot he dao or somewhere
  //38.5M to the dao, dao allocation and future team, 3 m from airdrop, 6.5M from team current team //
  const maxInitialMint = ethers.utils.parseEther("48000000"); //48M

  await execute(
    // execute function call on contract
    "AphraToken",
    { from: deployer, log: true },
    "setMinter",
    ...[Minter.address]
  );
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
})();
