const { ethers } = require("hardhat");
// APHRA AIRDROP RELEASE SET https://dune.xyz/androolloyd/AphraFinance for the ecosystem drop list
// the following were manually added to the csv prior to generation to say thanks for their work
// 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E (boringcrypto.eth)
// 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E (andrecronje.eth)

const AIRDROP_MERKLE_ROOT =
  "0xf0ec4d75057a5e1ccb9ed400b1cec9738fae58e16abe211a02b37f36cb04f882"; //release dropset
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const ve = await deployments.get("veAPHRA");
  const airdropClaim = await deploy("AirdropClaim", {
    from: deployer,
    args: [deployer, AIRDROP_MERKLE_ROOT, ve.address],
    log: true,
  });
};
module.exports.tags = ["AirdropClaim"];
