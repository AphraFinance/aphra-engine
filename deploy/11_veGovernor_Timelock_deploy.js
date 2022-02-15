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
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const timelockDeployment = await deploy("Timelock", {
    from: deployer,
    args: [deployer, TWO_DAYS], //2 days
    log: true,
  });
  const veAPHRA = await ethers.getContract("veAPHRA");

  await deploy("veGovernor", {
    from: deployer,
    args: [timelockDeployment.address, veAPHRA.address, deployer], //(address timelock_, address ve_, address guardian_)
    log: true,
  });

  // const veGovernor = await ethers.getContract("veGovernor");
  // const Timelock = await ethers.getContract("Timelock");
  //
  // const { timestamp } = await ethers.provider.getBlock("latest");
  // const queueSetPendingAdmin = await Timelock.functions.queueTransaction(
  //   Timelock.address,
  //   EMPTY,
  //   Timelock.interface.getSighash("setPendingAdmin(address)"),
  //   Timelock.interface.encodeFunctionData("setPendingAdmin(address)", [
  //     veGovernor.address,
  //   ]),
  //   timestamp + TWO_DAYS + 50
  // );

  //wait two days + 1 milisecond
  // const executeSetPendingAdmin = await Timelock.functions.executeTransaction(
  //   Timelock.address,
  //   "0x",
  //   Timelock.interface.getSighash("setPendingAdmin(address)"),
  //   Timelock.interface.functions.encode.setPendingAdmin(veGovernor.address),
  //   TWO_DAYS + 1
  // );

  // const acceptAdminTx = await veGovernor.functions.__acceptAdmin();
  // console.log(await acceptAdminTx.wait());
};
module.exports.tags = ["veGovernor", "Timelock"];
