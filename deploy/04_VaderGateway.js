module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer, vader, usdv, vaderMinter } = await getNamedAccounts();
  const multiRolesAuthority = await deployments.get("MultiRolesAuthority");
  await deploy("VaderGateway", {
    from: deployer,
    args: [vaderMinter, deployer, multiRolesAuthority.address, vader, usdv],
    log: true,
  });
};
module.exports.tags = ["VaderGateway"];
module.exports.dependencies = ["MultiRolesAuthority"];
