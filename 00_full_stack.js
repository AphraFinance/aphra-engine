const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run, getNamedAccounts } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

async function main() {
  console.log(ethers);
  // const [DEPLOYER, ALICE, BOB, CHARLIE, DAN] = await ethers.getSigners();
  const { deployer } = await getNamedAccounts();
  consol.log(deployer);
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
  const authority = await deploy("MultiRolesAuthority", [GOVERNANCE, "0x"]); // <-- add in constructor args like line 19 vvvv
  // const token = await deploy("AphraToken"); // <-- add in constructor args like line 19 vvvv
  // const gauges = await deploy("GaugeFactory"); // <-- add in constructor args like line 19 vvvv
  // const bribes = await deploy("BribeFactory"); // <-- add in constructor args like line 19 vvvv
  // const ve = await deploy("veAPHRA", [token.address, GOVERNANCE, authority]); // <-- add in constructor args like line 19 vvvv
  // const ve_dist = await deploy("veAPHRA", [ve.address]); // <-- add in constructor args like line 19 vvvv
  // const vaderGateway = await deploy("VaderGateway", [
  //   VADER_MINTER,
  //   GOVERNANCE,
  //   authority,
  //   VADER_ADDR,
  //   USDV_ADDR,
  // ]); // <-- add in constructor args like line 19 vvvv
  // const voter = await deploy("Voter", [
  //   GOVERNANCE,
  //   authority,
  //   ve.address,
  //   gauges.address,
  //   bribes.address,
  // ]); // <-- add in constructor args like line 19 vvvv
  // const minter = await deploy("Minter", [
  //   voter.address,
  //   ve.address,
  //   ve_dist.address,
  // ]); // <-- add in constructor args like line 19 vvvv
  // const airdropClaim = await deploy("AirdropClaim", [
  //   "0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55", //alice test hash
  //   ve.address,
  // ]); // <-- add in constructor args like line 19 vvvv
  //deploy and then hand off to governance

  await token.setMinter(minter.address);
  await ve.setVoter(voter.address);
  await ve_dist.setDepositor(minter.address);
  // await voter.initialize(
  //   [
  //   ],
  //   minter.address
  // );
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

  console.log("\n\n 📡 Deploying...\n");

  const yourContract = await deploy("YourContract"); // <-- add in constructor args like line 19 vvvv
  // use for local token bridging
  // const mockToken = await deploy("MockERC20") // <-- add in constructor args like line 19 vvvv

  //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  //const secondContract = await deploy("SecondContract")

  // const exampleToken = await deploy("ExampleToken")
  // const examplePriceOracle = await deploy("ExamplePriceOracle")
  // const smartContractWallet = await deploy("SmartContractWallet",[exampleToken.address,examplePriceOracle.address])

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

  //If you want to verify your contract on tenderly.co (see setup details in the scaffold-eth README!)
  /*
    await tenderlyVerify(
      {contractName: "YourContract",
       contractAddress: yourContract.address
    })
    */

  console.log(
    " 💾  Artifacts (address, abi, and args) saved to: ",
    chalk.blue("packages/hardhat/artifacts/"),
    "\n\n"
  );
}

const deploy = async (
  contractName,
  _args = [],
  overrides = {},
  libraries = {}
) => {
  console.log(` 🛰  Deploying: ${contractName}`);

  const contractArgs = _args || [];
  const contractArtifacts = await ethers.getContractFactory(contractName, {
    libraries: libraries,
  });
  const deployed = await contractArtifacts.deploy(...contractArgs, overrides);
  const encoded = abiEncodeArgs(deployed, contractArgs);
  fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);

  let extraGasInfo = "";
  if (deployed && deployed.deployTransaction) {
    const gasUsed = deployed.deployTransaction.gasLimit.mul(
      deployed.deployTransaction.gasPrice
    );
    extraGasInfo = `${utils.formatEther(gasUsed)} ETH, tx hash ${
      deployed.deployTransaction.hash
    }`;
  }

  console.log(
    " 📄",
    chalk.cyan(contractName),
    "deployed to:",
    chalk.magenta(deployed.address)
  );
  console.log(" ⛽", chalk.grey(extraGasInfo));

  await tenderly.persistArtifacts({
    name: contractName,
    address: deployed.address,
  });

  if (!encoded || encoded.length <= 2) return deployed;
  fs.writeFileSync(`artifacts/${contractName}.args`, encoded.slice(2));

  return deployed;
};

// ------ utils -------

// abi encodes contract arguments
// useful when you want to manually verify the contracts
// for example, on Etherscan
const abiEncodeArgs = (deployed, contractArgs) => {
  // not writing abi encoded args if this does not pass
  if (
    !contractArgs ||
    !deployed ||
    !R.hasPath(["interface", "deploy"], deployed)
  ) {
    return "";
  }
  const encoded = utils.defaultAbiCoder.encode(
    deployed.interface.deploy.inputs,
    contractArgs
  );
  return encoded;
};

const isSolidity = (fileName) =>
  fileName.indexOf(".sol") >= 0 &&
  fileName.indexOf(".swp") < 0 &&
  fileName.indexOf(".swap") < 0;

const readArgsFile = (contractName) => {
  let args = [];
  try {
    const argsFile = `./contracts/${contractName}.args`;
    if (!fs.existsSync(argsFile)) return args;
    args = JSON.parse(fs.readFileSync(argsFile));
  } catch (e) {
    console.log(e);
  }
  return args;
};

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// If you want to verify on https://tenderly.co/
const tenderlyVerify = async ({ contractName, contractAddress }) => {
  let tenderlyNetworks = [
    "kovan",
    "goerli",
    "mainnet",
    "rinkeby",
    "ropsten",
    "matic",
    "mumbai",
    "xDai",
    "POA",
  ];
  let targetNetwork = process.env.HARDHAT_NETWORK || config.defaultNetwork;

  if (tenderlyNetworks.includes(targetNetwork)) {
    console.log(
      chalk.blue(
        ` 📁 Attempting tenderly verification of ${contractName} on ${targetNetwork}`
      )
    );

    await tenderly.persistArtifacts({
      name: contractName,
      address: contractAddress,
    });

    let verification = await tenderly.verify({
      name: contractName,
      address: contractAddress,
      network: targetNetwork,
    });

    return verification;
  } else {
    console.log(
      chalk.grey(` 🧐 Contract verification not supported on ${targetNetwork}`)
    );
  }
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
