const { ethers } = require("hardhat");
const AIRDROP_MERKLE_ROOT =
  "0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55"; //alice test hash
//TODO: set for release
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ve = await deployments.get("veAPHRA");
  const airdropClaim = await deploy("AirdropClaim", {
    from: deployer,
    args: [AIRDROP_MERKLE_ROOT, ve.address],
    log: true,
  });
};
module.exports.tags = ["AirdropClaim"];
module.exports.dependencies = ["veAPHRA"];
