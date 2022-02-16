const { ethers } = require("hardhat");
const {
  USDV_ADDR,
  VADER_ADDR,
  ROLES,
  POOL,
  EMPTY,
} = require("../aphraAddressConfig");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { getContract } = ethers;
  const { deploy, execute } = deployments;
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
  // await Voter.functions.initialize([], Minter.address);
  await execute(
    // execute function call on contract
    "Voter",
    { from: deployer, log: true },
    "initialize",
    ...[[], Minter.address]
  );
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
};
module.exports.tags = ["SystemOnline"];
module.exports.runAtEnd = true;
module.exports.depedencies = [
  "AphraToken",
  "Minter",
  "Voter",
  "veAPHRA",
  "ve_dist",
];
