const { ethers } = require("hardhat");
const { GOVERNANCE } = require("../aphraAddressConfig");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const MultiRolesAuthority = await deployments.get("MultiRolesAuthority");
  const ve = await deployments.get("veAPHRA");
  const ve_dist = await deployments.get("ve_dist");
  const voter = await deployments.get("Voter");
  const minter = await deploy("MinterV2", {
    from: deployer,
    args: [
      GOVERNANCE,
      MultiRolesAuthority.address,
      "0x42Fd5B17D55F243c3fF28a38bb49bcCbEf48a7B0", //voter.address,
      "0x6f5A22E1508410E40bFeCf3B18Bc9DcC143Ed906", //ve.address,
      "0xc2D329f73493dBC4e2E52C11f9499a379300dc35", //ve_dist.address,
      "0xB8c93312FaE3F881E82632260fB7e9b4b15C4520", //burned airdrop
    ],
    log: true,
  });
};
module.exports.tags = ["MinterV2"];
module.exports.depedencies = ["veAPHRA", "ve_dist", "Voter"];
