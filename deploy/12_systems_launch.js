const { ethers } = require("hardhat");
const {
  USDV_ADDR,
  VADER_ADDR,
  ROLES,
  POOL,
  EMPTY,
} = require("../aphraAddressConfig");
const { chalk } = require("chalk");
const TWO_DAYS = 172800;
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { getContract } = ethers;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const Token = await getContract("AphraToken");
  const veAPHRA = await getContract("veAPHRA");
  const ve_dist = await getContract("ve_dist");
  const Minter = await getContract("Minter");
  const Voter = await getContract("Voter");
  await Token.functions.setMinter(Minter.address);
  await veAPHRA.functions.setVoter(Voter.address);
  await ve_dist.functions.setDepositor(Minter.address);
  await Voter.functions.initialize([], Minter.address);
  await Minter.functions.initialize(
    [], //veLock
    [], //veLockAmount
    [], //vesting lock
    [], //vesting amount
    ethers.BigNumber.from("100000000000000000000000000")
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
