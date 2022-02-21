const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read } = deployments;
  const { deployer, androolloyd, tekka, ehjc, rohmanus, greenbergz, grutte } =
    await getNamedAccounts();

  const AirdropClaim = await ethers.getContract("AirdropClaim");

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

  const rawLockReceivers = [AirdropClaim.address];
  const rawLockAmounts = [AIRDROP_ALLOC];

  //3 m from airdrop, 6.5M from team
  const maxInitialMint = ethers.utils.parseEther("9500000"); //9.5M

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
