// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");
const AIRDROP_MERKLE_ROOT =
  "0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55"; //alice test hash
const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(deployer);
  const chainId = await getChainId();
  const empty_address = "0x0000000000000000000000000000000000000000";
  const GOVERNANCE = "0x2101a22A8A6f2b60eF36013eFFCef56893cea983";
  const POOL = "0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c";
  const FACTORY = "0xB9fC157394Af804a3578134A6585C0dc9cc990d4";
  const XVADER = "0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369";
  const UNIROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const VADER_MINTER = "0x00aadC47d91fD9CaC3369E6045042f9F99216B98";
  const VADER_ADDR = "0x2602278EE1882889B946eb11DC0E810075650983";
  const USDV_ADDR = "0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe";

  // npx
  const multiRolesAuthority = await deploy("MultiRolesAuthority", {
    args: [GOVERNANCE, empty_address],
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv
  const token = await deploy("AphraToken", { from: deployer, log: true }); // <-- add in constructor args like line 19 vvvv
  const GaugeFactory = await deployments.getArtifact(
    "srcBuild/Gauge.sol:GaugeFactory"
  );
  const gauges = await deploy("GaugeFactory", {
    contract: GaugeFactory,
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv

  const vaultFactory = await deploy("VaultFactory", {
    from: deployer,
    args: [deployer, multiRolesAuthority.address],
  });

  const VaultFactory = await ethers.getContract(
    "VaultFactory",
    vaultFactory.address
  );
  const vaderVault = await VaultFactory.deployVault(VADER_ADDR);
  const BribeFactory = await deployments.getArtifact(
    "srcBuild/Bribe.sol:BribeFactory"
  );
  const bribes = await deploy("BribeFactory", {
    contract: BribeFactory,
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv
  const ve = await deploy("veAPHRA", {
    args: [token.address, GOVERNANCE, multiRolesAuthority.address],
    from: deployer,
    log: true,
  }); // <-- add in constructor args like line 19 vvvv
  const ve_dist = await deploy("veAPHRA", {
    from: deployer,
    args: [ve.address],
  }); // <-- add in constructor args like line 19 vvvv
  const vaderGateway = await deploy("VaderGateway", {
    from: deployer,
    args: [
      VADER_MINTER,
      GOVERNANCE,
      multiRolesAuthority.address,
      VADER_ADDR,
      USDV_ADDR,
    ],
  }); // <-- add in constructor args like line 19 vvvv
  const voter = await deploy("Voter", {
    from: deployer,
    args: [
      GOVERNANCE,
      multiRolesAuthority.address,
      ve.address,
      gauges.address,
      bribes.address,
    ],
  }); // <-- add in constructor args like line 19 vvvv
  const minter = await deploy("Minter", {
    from: deployer,
    args: [voter.address, ve.address, ve_dist.address],
  }); // <-- add in constructor args like line 19 vvvv
  const airdropClaim = await deploy("AirdropClaim", {
    from: deployer,
    args: [AIRDROP_MERKLE_ROOT, ve.address],
  }); // <-- add in constructor args like line 19 vvvv
  //deploy and then hand off to governance

  const vaultConfigurationModule = await deploy("VaultConfigurationModule", {
    from: deployer,
    args: [deployer, multiRolesAuthority.address],
  });
  const vaultInitializationModule = await deploy("VaultInitializationModule", {
    from: deployer,
    args: [
      vaultConfigurationModule.address,
      deployer,
      multiRolesAuthority.address,
    ],
  });
  // multiRolesAuthority.setUserRole(address(minter), uint8(ROLES.MINTER), true);
  // multiRolesAuthority.setRoleCapability(uint8(ROLES.MINTER), AphraToken.mint.selector, true);

  const Vault = ethers.getContractFactory("Vault");
  const ROLES = {
    GOVERNANCE: 0,
    VAULT_CONFIG: 1,
    VAULT_INIT_MODULE: 2,
    VAULT: 3,
    STRATEGY: 4,
    GAUGE: 5,
    BRIBE: 6,
    VOTER: 7,
    VE: 8,
    VE_DIST: 9,
  };

  // VAULT CONFIG module permissions
  multiRolesAuthority.setUserRole(
    vaultConfigurationModule.address,
    ROLES.VAULT_CONFIG,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT_CONFIG,

    Vault.setFeePercent.selector,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT_CONFIG,

    Vault.setHarvestDelay.selector,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT_CONFIG,

    Vault.setHarvestWindow.selector,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT_CONFIG,

    Vault.setTargetFloatPercent.selector,
    true
  );

  //vault init module permissions
  multiRolesAuthority.setUserRole(
    vaultInitializationModule.address,
    ROLES.VAULT_INIT_MODULE,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT_INIT_MODULE,
    Vault.initialize.selector,
    true
  );
  await vaultInitializationModule.initializeVault(vault.address);

  const strategy1 = await deploy("USDVOverPegStrategy", {
    from: deployer,
    args: [
      VADER_ADDR,
      GOVERNANCE,
      multiRolesAuthority.address,
      POOL,
      XVADER,
      vaderGateway.address,
      UNIROUTER,
      WETH,
    ],
  });
  //setup setup strategy as a valid auth for the minter
  multiRolesAuthority.setUserRole(strategy1.address, ROLES.STRATEGY, true);
  multiRolesAuthority.setRoleCapability(
    ROLES.STRATEGY,
    vaderGateway.partnerMint.selector,
    true
  );
  multiRolesAuthority.setRoleCapability(
    ROLES.STRATEGY,
    vaderGateway.partnerBurn.selector,
    true
  );

  //setup vault as as a valid auth for the strategy minter
  multiRolesAuthority.setUserRole(vault.address, ROLES.VAULT, true);
  multiRolesAuthority.setRoleCapability(
    ROLES.VAULT,
    strategy1.mint.selector,
    true
  );

  await token.setMinter(minter.address);
  await ve.setVoter(voter.address);
  await ve_dist.setDepositor(minter.address);
  await voter.initialize([vault.address], minter.address);
  // await minter.initialize(
  //   [
  //   ], //veLock
  //   [
  //   ], //veLockAmount
  //   [
  //   ], //vesting lock
  //   [
  //
  //   ], //vesting amount
  //   ethers.BigNumber.from("100000000000000000000000000")
  // );

  // Getting a previously deployed contract

  /*
    //If you want to send value to an address from the deployer
    const deployerWallet = ethers.provider.getSigner()
    await deployerWallet.sendTransaction({
      to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
      value: ethers.utils.parseEther("0.001")
    })
    */

  /*
    //If you want to send some ETH to a contract on deploy (make your constructor payable!)
    const yourContract = await deploy("YourContract", [], {
    value: ethers.utils.parseEther("0.05")
    });
    */

  /*
    //If you want to link a library into your contract:
    // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
    const yourContract = await deploy("YourContract", [], {}, {
     LibraryName: **LibraryAddress**
    });
    */

  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
  // You don't want to verify on localhost
  // try {
  //   if (chainId !== localChainId) {
  //     await run("verify:verify", {
  //       address: YourContract.address,
  //       contract: "contracts/YourContract.sol:YourContract",
  //       contractArguments: [],
  //     });
  //   }
  // } catch (error) {
  //   console.error(error);
  // }
};
module.exports.tags = ["AphraToken"];
