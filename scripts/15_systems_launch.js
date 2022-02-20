const hre = require("hardhat");
const { getNamedAccounts, deployments, ethers } = hre;
(async () => {
  const { execute, read } = deployments;
  const { deployer, androolloyd, tekka, ehjc, rohamanus, greenbergz, grutte } =
    await getNamedAccounts();

  const AirdropClaim = await ethers.getContract("AirdropClaim");
  console.log("Token Vesting Contract deployed for:", androolloyd);

  const AIRDROP_ALLOC = ethers.utils.parseEther("3000000"); //3m

  //each alloc below is sent twice, once into ve and once into raw vesting
  const FOUNDER_ALLOC = ethers.utils.parseEther("1000000"); //1M x2 = 2M
  const EARLY_TEAM_ALLOC = ethers.utils.parseEther("500000"); //500k x2 = 1M
  const TEAM_ALLOC = ethers.utils.parseEther("250000"); //250k x 2 == 500k

  const veLockReceivers = [
    androolloyd,
    tekka,
    ehjc,
    rohamanus,
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

  const androolloydVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[androolloyd]
  );
  console.log(androolloydVesting);
  const tekkaVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[tekka]
  );
  const ehjcVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[ehjc]
  );
  const rohamanusVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[rohamanus]
  );
  const greenbergzVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[greenbergz]
  );
  const grutteVesting = await read(
    "TokenVestingFactory",
    { from: deployer, log: true },
    "getVestingContract",
    ...[grutte]
  );
  const rawLockReceivers = [
    androolloydVesting, //androolloyd.eth
    tekkaVesting,
    ehjcVesting,
    rohamanusVesting,
    greenbergzVesting,
    grutteVesting,
    AirdropClaim.address,
  ];
  const rawLockAmounts = [
    FOUNDER_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    EARLY_TEAM_ALLOC,
    TEAM_ALLOC,
    AIRDROP_ALLOC,
  ];

  //3 m from airdrop, 6.5M from team
  const maxInitialMint = ethers.utils.parseEther("9500000");

  // //setup vesting
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
})();
