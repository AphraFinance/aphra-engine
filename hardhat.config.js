require("dotenv").config();
const { utils } = require("ethers");
const fs = require("fs");
const chalk = require("chalk");
const addressBook = require("./aphraAddressConfig");
// require("@nomiclabs/hardhat-waffle");
// require("@tenderly/hardhat-tenderly");
require("hardhat-deploy");
require("hardhat-gas-reporter");
// require("@tenderly/hardhat-tenderly");
require("hardhat-deploy-ethers");
require("@nomiclabs/hardhat-etherscan");
const prompt = require("prompt-sync")();

const { isAddress, getAddress, formatUnits, parseUnits } = utils;

/*
      📡 This is where you configure your deploy configuration for 🏗 scaffold-eth

      check out `packages/scripts/deploy.js` to customize your deployment

      out of the box it will auto deploy anything in the `contracts` folder and named *.sol
      plus it will use *.args for constructor args
*/

//
// Select the network you want to deploy to here:
//
const defaultNetwork = "hardhat";

const mainnetGwei = 35;

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    if (defaultNetwork !== "localhost") {
      console.log(
        "☢️ WARNING: No mnemonic file created for a deploy account. Try `yarn run generate` and then `yarn run account`."
      );
    }
  }
  return "";
}

module.exports = {
  defaultNetwork,

  /**
   * gas reporter configuration that let's you know
   * an estimate of gas for contract deployments and function calls
   * More here: https://hardhat.org/plugins/hardhat-gas-reporter.html
   */
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP || null,
  },

  zksolc: {
    version: "0.1.0",
    compilerSource: "docker",
    settings: {
      optimizer: {
        enabled: true,
      },
      experimental: {
        dockerImage: "matterlabs/zksolc",
      },
    },
  },
  zkSyncDeploy: {
    zkSyncNetwork: "https://zksync2-testnet.zksync.dev",
    ethNetwork: "goerli",
  },

  tenderly: {
    project: "",
    username: "androolloyd",
  },
  // if you want to deploy to a testnet, mainnet, or xdai, you will need to configure:
  // 1. An Infura key (or similar)
  // 2. A private key for the deployer
  // DON'T PUSH THESE HERE!!!
  // An `example.env` has been provided in the Hardhat root. Copy it and rename it `.env`
  // Follow the directions, and uncomment the network you wish to deploy to.

  networks: {
    hardhat: {
      chainId: 1,
      forking: {
        // url: "https://eth-mainnet.alchemyapi.io/v2/K3OwSQSaGH_ol2Kpv4eZZP_npFld9wib", // <---- YOUR INFURA ID! (or it won't work)
        url: "http://erigon.dappnode:8545",
      },
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    localhost: {
      accounts: {
        mnemonic: mnemonic(),
      },
      url: "http://localhost:8545",
      /*
        notice no mnemonic here? it will just use account 0 of the hardhat node to deploy
        (you can put in a mnemonic here to set the deployer locally)

      */
    },

    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.RINKEBY_INFURA_KEY}`,
    //   accounts: [`${process.env.RINKEBY_DEPLOYER_PRIV_KEY}`],
    // },
    // kovan: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.KOVAN_INFURA_KEY}`,
    //   accounts: [`${process.env.KOVAN_DEPLOYER_PRIV_KEY}`],
    // },
    // mainnet: {
    //   url: `https://mainnet.infura.io/v3/${process.env.MAINNET_INFURA_KEY}`,
    //   accounts: [`${process.env.MAINNET_DEPLOYER_PRIV_KEY}`],
    // },
    // ropsten: {
    //   url: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_INFURA_KEY}`,
    //   accounts: [`${process.env.ROPSTEN_DEPLOYER_PRIV_KEY}`],
    // },
    // goerli: {
    //   url: `https://goerli.infura.io/v3/${process.env.GOERLI_INFURA_KEY}`,
    //   accounts: [`${process.env.GOERLI_DEPLOYER_PRIV_KEY}`],
    // },
    // xdai: {
    //   url: 'https://dai.poa.network',
    //   gasPrice: 1000000000,
    //   accounts: [`${process.env.XDAI_DEPLOYER_PRIV_KEY}`],
    // },

    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/XXXXXXXXXXXXXXXXXXXXXXX", // <---- YOUR INFURA ID! (or it won't work)
      saveDeployments: true,
      tags: ["rinkeby"],
      //    url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXX/eth/rinkeby", // <---- YOUR MORALIS ID! (not limited to infura)

      accounts: {
        mnemonic: mnemonic(),
      },
    },
    kovan: {
      url: "https://kovan.infura.io/v3/460f40a260564ac4a4f4b3fffb032dad", // <---- YOUR INFURA ID! (or it won't work)

      //    url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXX/eth/kovan", // <---- YOUR MORALIS ID! (not limited to infura)

      accounts: {
        mnemonic: mnemonic(),
      },
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/460f40a260564ac4a4f4b3fffb032dad", // <---- YOUR INFURA ID! (or it won't work)

      //      url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXXXX/eth/mainnet", // <---- YOUR MORALIS ID! (not limited to infura)

      gasPrice: mainnetGwei * 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/460f40a260564ac4a4f4b3fffb032dad", // <---- YOUR INFURA ID! (or it won't work)

      //      url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXXXX/eth/ropsten",// <---- YOUR MORALIS ID! (not limited to infura)

      accounts: {
        mnemonic: mnemonic(),
      },
    },
    goerli: {
      url: "https://goerli.infura.io/v3/460f40a260564ac4a4f4b3fffb032dad", // <---- YOUR INFURA ID! (or it won't work)

      //      url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXXXX/eth/goerli", // <---- YOUR MORALIS ID! (not limited to infura)

      accounts: {
        mnemonic: mnemonic(),
      },
    },
    xdai: {
      url: "https://rpc.xdaichain.com/",
      gasPrice: 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    polygon: {
      url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXx/polygon/mainnet", // <---- YOUR MORALIS ID! (not limited to infura)
      gasPrice: 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    mumbai: {
      url: "https://speedy-nodes-nyc.moralis.io/XXXXXXXXXXXXXXXXXXXXXXX/polygon/mumbai", // <---- YOUR MORALIS ID! (not limited to infura)
      gasPrice: 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },

    matic: {
      url: "https://rpc-mainnet.maticvigil.com/",
      gasPrice: 1000000000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    rinkebyArbitrum: {
      url: "https://rinkeby.arbitrum.io/rpc",
      gasPrice: 0,
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l1: "rinkeby",
      },
    },
    localArbitrum: {
      url: "http://localhost:8547",
      gasPrice: 0,
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l1: "localArbitrumL1",
      },
    },
    localArbitrumL1: {
      url: "http://localhost:7545",
      gasPrice: 0,
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l2: "localArbitrum",
      },
    },
    optimism: {
      url: "https://mainnet.optimism.io",
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l1: "mainnet",
      },
    },
    kovanOptimism: {
      url: "https://kovan.optimism.io",
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l1: "kovan",
      },
    },
    localOptimism: {
      url: "http://localhost:8545",
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l1: "localOptimismL1",
      },
    },
    localOptimismL1: {
      url: "http://localhost:9545",
      gasPrice: 0,
      accounts: {
        mnemonic: mnemonic(),
      },
      companionNetworks: {
        l2: "localOptimism",
      },
    },
    localAvalanche: {
      url: "http://localhost:9650/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43112,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    fujiAvalanche: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    mainnetAvalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      gasPrice: 225000000000,
      chainId: 43114,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    testnetHarmony: {
      url: "https://api.s0.b.hmny.io",
      gasPrice: 1000000000,
      chainId: 1666700000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
    mainnetHarmony: {
      url: "https://api.harmony.one",
      gasPrice: 1000000000,
      chainId: 1666600000,
      accounts: {
        mnemonic: mnemonic(),
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.11",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  ovm: {
    solcVersion: "0.7.6",
  },
  namedAccounts: {
    empty: {
      default: "0x0000000000000000000000000000000000000000",
    },
    androolloyd: {
      default: "0x86d3ee9ff0983bc33b93cc8983371a500f873446",
    },
    tekka: {
      default: "0x2BB9Ad8ED667d6eDb0bf10dbBB0b2beed560bE41",
    },
    ehjc: {
      default: "0xf1afdD3257B0Cb73C234ca6f73B1B2316f551600",
    },
    greenbergz: {
      default: "0x0ABd85014e890eb3b30C4Eb7Da5DDd4548c3ddCD",
    },
    rohmanus: {
      default: "0x0ed609C9acb9699D362c986fEdEED9C6DD1396d0",
    },
    grutte: {
      default: "0x187843b25ecd6039addDBb6D92DDF8219bfb94FD",
    },
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
    guardian: {
      default: addressBook.GOVERNANCE,
      1: addressBook.GOVERNANCE,
    },
    vader: {
      default: addressBook.VADER_ADDR,
    },
    usdv: {
      default: addressBook.USDV_ADDR,
    },
    USDV3Crv: {
      default: addressBook.POOL,
    },
    vaderMinter: {
      default: addressBook.VADER_MINTER,
    },
    xvader: {
      default: addressBook.XVADER,
    },
    unirouter: {
      default: addressBook.UNIROUTER,
    },
    weth: {
      default: addressBook.WETH,
    },
  },
  etherscan: {
    apiKey: "WZEYP1G9K1YC8R3VEZV6YAR72TA8ZX28DY",
  },
  paths: {
    sources: "./srcBuild",
    tests: "./test",
    cache: "./cache",
    artifacts: "./build",
  },
};

const DEBUG = true;

function debug(text) {
  if (DEBUG) {
    console.log(text);
  }
}

task("wallet", "Create a wallet (pk) link", async (_, { ethers }) => {
  const randomWallet = ethers.Wallet.createRandom();
  const privateKey = randomWallet._signingKey().privateKey;
  console.log("🔐 WALLET Generated as " + randomWallet.address + "");
  console.log("🔗 http://localhost:3000/pk#" + privateKey);
});

task("fundedwallet", "Create a wallet (pk) link and fund it with deployer?")
  .addOptionalParam(
    "amount",
    "Amount of ETH to send to wallet after generating"
  )
  .addOptionalParam("url", "URL to add pk to")
  .setAction(async (taskArgs, { network, ethers }) => {
    const randomWallet = ethers.Wallet.createRandom();
    const privateKey = randomWallet._signingKey().privateKey;
    console.log("🔐 WALLET Generated as " + randomWallet.address + "");
    const url = taskArgs.url ? taskArgs.url : "http://localhost:3000";

    let localDeployerMnemonic;
    try {
      localDeployerMnemonic = fs.readFileSync("./mnemonic.txt");
      localDeployerMnemonic = localDeployerMnemonic.toString().trim();
    } catch (e) {
      /* do nothing - this file isn't always there */
    }

    const amount = taskArgs.amount ? taskArgs.amount : "0.01";
    const tx = {
      to: randomWallet.address,
      value: ethers.utils.parseEther(amount),
    };

    // SEND USING LOCAL DEPLOYER MNEMONIC IF THERE IS ONE
    // IF NOT SEND USING LOCAL HARDHAT NODE:
    if (localDeployerMnemonic) {
      let deployerWallet = new ethers.Wallet.fromMnemonic(
        localDeployerMnemonic
      );
      deployerWallet = deployerWallet.connect(ethers.provider);
      console.log(
        "💵 Sending " +
          amount +
          " ETH to " +
          randomWallet.address +
          " using deployer account"
      );
      const sendresult = await deployerWallet.sendTransaction(tx);
      console.log("\n" + url + "/pk#" + privateKey + "\n");
    } else {
      console.log(
        "💵 Sending " +
          amount +
          " ETH to " +
          randomWallet.address +
          " using local node"
      );
      console.log("\n" + url + "/pk#" + privateKey + "\n");
      return send(ethers.provider.getSigner(), tx);
    }
  });

task(
  "generate",
  "Create a mnemonic for builder deploys",
  async (_, { ethers }) => {
    const bip39 = require("bip39");
    const { hdkey } = require("ethereumjs-wallet/dist");
    const mnemonic = bip39.generateMnemonic();
    if (DEBUG) console.log("mnemonic", mnemonic);
    const seed = await bip39.mnemonicToSeed(mnemonic);
    if (DEBUG) console.log("seed", seed);
    const hdwallet = hdkey.fromMasterSeed(seed);
    const wallet_hdpath = "m/44'/60'/0'/0/";
    const account_index = 0;
    const fullPath = wallet_hdpath + account_index;
    if (DEBUG) console.log("fullPath", fullPath);
    const derrived = hdwallet.derivePath(fullPath);
    const privateKey = "0x" + derrived._hdkey._privateKey.toString("hex");
    if (DEBUG) console.log("privateKey", privateKey);
    const EthUtil = require("ethereumjs-util");
    const address =
      "0x" +
      EthUtil.privateToAddress(derrived._hdkey._privateKey).toString("hex");
    console.log(
      "🔐 Account Generated as " +
        address +
        " and set as mnemonic in packages/hardhat"
    );
    console.log(
      "💬 Use 'yarn run account' to get more information about the deployment account."
    );

    fs.writeFileSync("./" + address + ".txt", mnemonic.toString());
    fs.writeFileSync("./mnemonic.txt", mnemonic.toString());
  }
);

task(
  "mineContractAddress",
  "Looks for a deployer account that will give leading zeros"
)
  .addParam("searchFor", "String to search for")
  .setAction(async (taskArgs, { network, ethers }) => {
    let contract_address = "";
    let address;

    const bip39 = require("bip39");
    const { hdkey } = require("ethereumjs-wallet/dist");

    let mnemonic = "";
    while (contract_address.indexOf(taskArgs.searchFor) != 0) {
      mnemonic = bip39.generateMnemonic();
      if (DEBUG) console.log("mnemonic", mnemonic);
      const seed = await bip39.mnemonicToSeed(mnemonic);
      if (DEBUG) console.log("seed", seed);
      const hdwallet = hdkey.fromMasterSeed(seed);
      const wallet_hdpath = "m/44'/60'/0'/0/";
      const account_index = 0;
      const fullPath = wallet_hdpath + account_index;
      if (DEBUG) console.log("fullPath", fullPath);
      const derrived = hdwallet.derivePath(fullPath);
      const privateKey = "0x" + derrived._hdkey._privateKey.toString("hex");
      if (DEBUG) console.log("privateKey", privateKey);
      const EthUtil = require("ethereumjs-util");
      address =
        "0x" +
        EthUtil.privateToAddress(derrived._hdkey._privateKey).toString("hex");

      const rlp = require("rlp");
      const keccak = require("keccak");

      const nonce = 0x00; // The nonce must be a hex literal!
      const sender = address;

      const input_arr = [sender, nonce];
      const rlp_encoded = rlp.encode(input_arr);

      const contract_address_long = keccak("keccak256")
        .update(rlp_encoded)
        .digest("hex");

      contract_address = contract_address_long.substring(24); // Trim the first 24 characters.
    }

    console.log(
      "⛏  Account Mined as " +
        address +
        " and set as mnemonic in packages/hardhat"
    );
    console.log(
      "📜 This will create the first contract: " +
        chalk.magenta("0x" + contract_address)
    );
    console.log(
      "💬 Use 'yarn run account' to get more information about the deployment account."
    );

    fs.writeFileSync(
      "./" + address + "_produces" + contract_address + ".txt",
      mnemonic.toString()
    );
    fs.writeFileSync("./mnemonic.txt", mnemonic.toString());
  });

task(
  "account",
  "Get balance informations for the deployment account.",
  async (_, { ethers }) => {
    const hdkey = require("ethereumjs-wallet/hdkey");
    const bip39 = require("bip39");
    try {
      const mnemonic = fs.readFileSync("./mnemonic.txt").toString().trim();
      if (DEBUG) console.log("mnemonic", mnemonic);
      const seed = await bip39.mnemonicToSeed(mnemonic);
      if (DEBUG) console.log("seed", seed);
      const hdwallet = hdkey.fromMasterSeed(seed);
      const wallet_hdpath = "m/44'/60'/0'/0/";
      const account_index = 0;
      const fullPath = wallet_hdpath + account_index;
      if (DEBUG) console.log("fullPath", fullPath);
      const derrived = hdwallet.derivePath(fullPath);
      const privateKey = "0x" + derrived._hdkey._privateKey.toString("hex");
      if (DEBUG) console.log("privateKey", privateKey);
      const EthUtil = require("ethereumjs-util");
      const address =
        "0x" + EthUtil.privateToAddress(wallet._privKey).toString("hex");

      const qrcode = require("qrcode-terminal");
      qrcode.generate(address);
      console.log("‍📬 Deployer Account is " + address);
      for (const n in config.networks) {
        // console.log(config.networks[n],n)
        try {
          const provider = new ethers.providers.JsonRpcProvider(
            config.networks[n].url
          );
          const balance = await provider.getBalance(address);
          console.log(" -- " + n + " --  -- -- 📡 ");
          console.log("   balance: " + ethers.utils.formatEther(balance));
          console.log(
            "   nonce: " + (await provider.getTransactionCount(address))
          );
        } catch (e) {
          if (DEBUG) {
            console.log(e);
          }
        }
      }
    } catch (err) {
      console.log(`--- Looks like there is no mnemonic file created yet.`);
      console.log(
        `--- Please run ${chalk.greenBright("yarn generate")} to create one`
      );
    }
  }
);

async function addr(ethers, addr) {
  if (isAddress(addr)) {
    return getAddress(addr);
  }
  const accounts = await ethers.provider.listAccounts();
  if (accounts[addr] !== undefined) {
    return accounts[addr];
  }
  throw `Could not normalize address: ${addr}`;
}

task("accounts", "Prints the list of accounts", async (_, { ethers }) => {
  const accounts = await ethers.provider.listAccounts();
  accounts.forEach((account) => console.log(account));
});

task("blockNumber", "Prints the block number", async (_, { ethers }) => {
  const blockNumber = await ethers.provider.getBlockNumber();
  console.log(blockNumber);
});

task("balance", "Prints an account's balance")
  .addPositionalParam("account", "The account's address")
  .setAction(async (taskArgs, { ethers }) => {
    const balance = await ethers.provider.getBalance(
      await addr(ethers, taskArgs.account)
    );
    console.log(formatUnits(balance, "ether"), "ETH");
  });

function send(signer, txparams) {
  return signer.sendTransaction(txparams, (error, transactionHash) => {
    if (error) {
      debug(`Error: ${error}`);
    }
    debug(`transactionHash: ${transactionHash}`);
    // checkForReceipt(2, params, transactionHash, resolve)
  });
}

task("whitelistAuth", "whitelist asset")
  .addParam("asset", "avName of asset")
  .setAction(async (taskArgs, { network, ethers, deployments }) => {
    const { execute, read, save } = deployments;
    const { deployer, guardian } = await getNamedAccounts();
    let answer = prompt(`Execute Whitelist ${taskArgs.asset}: (y/n/exit) `);

    if (answer === "y") {
      const vaultDeployReceipt = await execute(
        // execute function call on contract
        "Voter",
        { from: guardian, log: true },
        "whitelistAsAuth",
        ...[taskArgs.asset]
      );
    }
  });

task("deployVault", "deploy Vault/Gauge/Bribe")
  .addParam("asset", "address of asset to configure")
  .addParam("symbol", "symbol of asset to configure")
  .setAction(async (taskArgs, { network, ethers, deployments }) => {
    const { execute, read, save } = deployments;
    const { deployer } = await getNamedAccounts();
    if (!taskArgs || !(taskArgs.asset && taskArgs.symbol))
      return process.exit(1);
    const { asset, symbol } = taskArgs;

    let answer = prompt(`Execute Deploy ${symbol} Vault: (y/n/exit) `);

    if (answer === "y") {
      const vaultDeployReceipt = await execute(
        // execute function call on contract
        "VaultFactory",
        { from: deployer, log: true },
        "deployVault",
        ...[asset]
      );

      const newVaultAddress = await read(
        "VaultFactory",
        { from: deployer, log: true },
        "getVaultFromUnderlying",
        ...[asset]
      );

      const VaultArtifact = await deployments.getArtifact("Vault");
      const vaultDeployment = {
        abi: VaultArtifact.abi,
        address: newVaultAddress,
        transactionHash: vaultDeployReceipt.transactionHash,
        receipt: newVaultAddress,
      };
      await save(`av${symbol}`, vaultDeployment);
    } else if (answer === "exit") {
      process.exit(1);
    }
    answer = prompt(`Execute Initialize ${symbol} Vault: (y/n/exit) `);

    if (answer === "y") {
      const newVaultAddress = await read(
        "VaultFactory",
        { from: deployer, nonce: 93, log: true },
        "getVaultFromUnderlying",
        ...[asset]
      );
      await execute(
        // execute function call on contract
        "VaultInitializationModule",
        { from: deployer, log: true },
        "initializeVault",
        ...[newVaultAddress]
      );
    } else if (answer === "exit") {
      process.exit(1);
    }
    answer = prompt(`Execute Deploy ${symbol} Gauge/Bribe: (y/n/exit) `);

    if (answer === "y") {
      const newVaultAddress = await read(
        "VaultFactory",
        { from: deployer, log: true },
        "getVaultFromUnderlying",
        ...[asset]
      );
      const gaugeTxn = await execute(
        // execute function call on contract
        "Voter",
        { from: deployer, log: true },
        "createGauge",
        ...[newVaultAddress]
      );
      for (let log of gaugeTxn.events) {
        if (log.event && log.event === "GaugeCreated") {
          const [gaugeAddress, creator, bribeAddress, asset] = log.args;

          const GaugeArtifact = await deployments.getArtifact("Gauge");
          const BribeArtifact = await deployments.getArtifact("Bribe");

          const gauge = {
            abi: GaugeArtifact.abi,
            address: gaugeAddress,
            transactionHash: gaugeTxn.transactionHash,
            receipt: gaugeTxn,
          };

          await save(`av${symbol}Gauge`, gauge);

          const bribe = {
            abi: BribeArtifact.abi,
            address: bribeAddress,
            transactionHash: gaugeTxn.transactionHash,
            receipt: gaugeTxn,
          };

          await save(`av${symbol}Bribe`, bribe);
        }
      }
    } else if (answer === "exit") {
      process.exit(1);
    }
  });

task("send", "Send ETH")
  .addParam("from", "From address or account index")
  .addOptionalParam("to", "To address or account index")
  .addOptionalParam("amount", "Amount to send in ether")
  .addOptionalParam("nonce", "nonce")
  .addOptionalParam("data", "Data included in transaction")
  .addOptionalParam("gasprice", "Price you are willing to pay in gwei")
  .addOptionalParam("gaslimit", "Limit of how much gas to spend")

  .setAction(async (taskArgs, { network, ethers }) => {
    const from = await addr(ethers, taskArgs.from);
    debug(`Normalized from address: ${from}`);
    const fromSigner = await ethers.provider.getSigner(from);

    let to;
    if (taskArgs.to) {
      to = await addr(ethers, taskArgs.to);
      debug(`Normalized to address: ${to}`);
    }

    const txRequest = {
      from: await fromSigner.getAddress(),
      to,
      value: parseUnits(
        taskArgs.amount ? taskArgs.amount : "0",
        "ether"
      ).toHexString(),
      gasPrice: parseUnits(
        taskArgs.gasPrice ? taskArgs.gasPrice : "140",
        "gwei"
      ).toHexString(),
      gasLimit: taskArgs.gasLimit ? taskArgs.gasLimit : 24000,
      chainId: network.config.chainId,
    };

    if (taskArgs && taskArgs.nonce) {
      txRequest["nonce"] = parseInt(taskArgs.nonce);
    }

    if (taskArgs.data !== undefined) {
      txRequest.data = taskArgs.data;
      debug(`Adding data to payload: ${txRequest.data}`);
    }
    debug(txRequest.gasPrice / 1000000000 + " gwei");
    debug(JSON.stringify(txRequest, null, 2));

    return send(fromSigner, txRequest);
  });
