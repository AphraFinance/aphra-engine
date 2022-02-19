const { ethers } = require("hardhat");
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer, guardian } = await getNamedAccounts();
  const veAPHRA = await ethers.getContract("veAPHRA");
  await deploy("TokenVestingFactory", {
    from: deployer,
    args: [deployer, veAPHRA.address], //2 days
    log: true,
  });
};
module.exports.tags = ["TokenVestingFactory", "TokenVesting"];
