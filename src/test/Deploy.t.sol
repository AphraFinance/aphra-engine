// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MultiRolesAuthority} from "../MultiRolesAuthority.sol";

import {IVaderMinter, IUniswap, USDVOverPegStrategy} from "../strategies/USDVOverPegStrategy.sol";
import {VaderGateway} from "../VaderGateway.sol";
import {IVaderMinterExtended} from "../interfaces/vader/IVaderMinterExtended.sol";
import {VaultInitializationModule} from "../modules/VaultInitializationModule.sol";
import {VaultConfigurationModule} from "../modules/VaultConfigurationModule.sol";

import {Strategy} from "../interfaces/Strategy.sol";

import {ICurve} from "../interfaces/StrategyInterfaces.sol";

import {Vault} from "../Vault.sol";
import {VaultFactory} from "../VaultFactory.sol";
import {GaugeFactory} from "../Gauges.sol";
import {BribeFactory} from "../Bribes.sol";
import {veAPHRA} from "../veAPHRA.sol";
import {ve_dist} from "../ve_dist.sol";
import {Minter} from "../Minter.sol";
import {Voter} from "../Voter.sol";
import {AphraToken} from "../AphraToken.sol";
import "./console.sol";
import "../AirdropClaim.sol";


contract DeployTest is DSTestPlus {
    VaultFactory vaultFactory;

    MultiRolesAuthority multiRolesAuthority;

    VaultConfigurationModule vaultConfigurationModule;

    VaultInitializationModule vaultInitializationModule;

    ERC20 underlying;

    ERC20 usdv;
    USDVOverPegStrategy strategy1;

    address constant GOVERNANCE = address(0x2101a22A8A6f2b60eF36013eFFCef56893cea983);
    address constant POOL = address(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
    address constant FACTORY = address(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
    address constant XVADER = address(0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369);
    address constant UNIROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IVaderMinterExtended constant VADER_MINTER = IVaderMinterExtended(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);

    IVaderMinter vaderGateway;

    AphraToken aphra;
    GaugeFactory gauges;
    BribeFactory bribes;
    veAPHRA Ve;
    ve_dist Ve_dist;
    Voter voter;
    Minter minter;
    AirdropClaim airdropClaim;
    /*


  const voter = await BaseV1Voter.deploy(ve.address, core.address, gauges.address, bribes.address);
  const minter = await BaseV1Minter.deploy(voter.address, ve.address, ve_dist.address);

  await token.setMinter(minter.address);
  await ve.setVoter(voter.address);
  await ve_dist.setDepositor(minter.address);
  await voter.initialize(["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83","0x04068da6c83afcfa0e13ba15a6696662335d5b75","0x321162Cd933E2Be498Cd2267a90534A804051b11","0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e","0x82f0b8b456c1a451378467398982d4834b6829c1","0xdc301622e621166bd8e82f2ca0a26c13ad0be355","0x1E4F97b9f9F913c46F1632781732927B9019C68b", "0x29b0Da86e484E1C0029B56e817912d778aC0EC69", "0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC", "0x7d016eec9c25232b01f23ef992d98ca97fc2af5a", "0x468003b688943977e6130f4f68f23aad939a1040","0xe55e19fb4f2d85af758950957714292dac1e25b2","0x4cdf39285d7ca8eb3f090fda0c069ba5f4145b37","0x6c021ae822bea943b2e66552bde1d2696a53fbb7","0x2a5062d22adcfaafbd5c541d4da82e4b450d4212","0x841fad6eae12c286d1fd18d1d525dffa75c7effe","0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0","0xad996a45fd2373ed0b10efa4a8ecb9de445a4302", "0xd8321aa83fb0a4ecd6348d4577431310a6e0814d", "0x5cc61a78f164885776aa610fb0fe1257df78e59b", "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9","0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475","0x85dec8c4b2680793661bca91a8f129607571863d","0x74b23882a30290451A17c44f4F05243b6b58C76d","0xf16e81dce15b08f326220742020379b855b87df9", "0x9879abdea01a879644185341f7af7d8343556b7a","0x00a35FD824c717879BF370E70AC6868b95870Dfb","0xc5e2b037d30a390e62180970b3aa4e91868764cd", "0x10010078a54396F62c96dF8532dc2B4847d47ED3"], minter.address);
  await minter.initialize(["0x5bDacBaE440A2F30af96147DE964CC97FE283305","0xa96D2F0978E317e7a97aDFf7b5A76F4600916021","0x95478C4F7D22D1048F46100001c2C69D2BA57380","0xC0E2830724C946a6748dDFE09753613cd38f6767","0x3293cB515Dbc8E0A8Ab83f1E5F5f3CC2F6bbc7ba","0xffFfBBB50c131E664Ef375421094995C59808c97","0x02517411F32ac2481753aD3045cA19D58e448A01","0xf332789fae0d1d6f058bfb040b3c060d76d06574","0xdFf234670038dEfB2115Cf103F86dA5fB7CfD2D2","0x0f2A144d711E7390d72BD474653170B201D504C8","0x224002428cF0BA45590e0022DF4b06653058F22F","0x26D70e4871EF565ef8C428e8782F1890B9255367","0xA5fC0BbfcD05827ed582869b7254b6f141BA84Eb","0x4D5362dd18Ea4Ba880c829B0152B7Ba371741E59","0x1e26D95599797f1cD24577ea91D99a9c97cf9C09","0xb4ad8B57Bd6963912c80FCbb6Baea99988543c1c","0xF9E7d4c6d36ca311566f46c81E572102A2DC9F52","0xE838c61635dd1D41952c68E47159329443283d90","0x111731A388743a75CF60CCA7b140C58e41D83635","0x0edfcc1b8d082cd46d13db694b849d7d8151c6d5","0xD0Bb8e4E4Dd5FDCD5D54f78263F5Ec8f33da4C95","0x9685c79e7572faF11220d0F3a1C1ffF8B74fDc65","0xa70b1d5956DAb595E47a1Be7dE8FaA504851D3c5","0x06917EFCE692CAD37A77a50B9BEEF6f4Cdd36422","0x5b0390bccCa1F040d8993eB6e4ce8DeD93721765"], [ethers.BigNumber.from("800000000000000000000000"),ethers.BigNumber.from("2376588000000000000000000"),ethers.BigNumber.from("1331994000000000000000000"),ethers.BigNumber.from("1118072000000000000000000"),ethers.BigNumber.from("1070472000000000000000000"),ethers.BigNumber.from("1023840000000000000000000"),ethers.BigNumber.from("864361000000000000000000"),ethers.BigNumber.from("812928000000000000000000"),ethers.BigNumber.from("795726000000000000000000"),ethers.BigNumber.from("763362000000000000000000"),ethers.BigNumber.from("727329000000000000000000"),ethers.BigNumber.from("688233000000000000000000"),ethers.BigNumber.from("681101000000000000000000"),ethers.BigNumber.from("677507000000000000000000"),ethers.BigNumber.from("676304000000000000000000"),ethers.BigNumber.from("642992000000000000000000"),ethers.BigNumber.from("609195000000000000000000"),ethers.BigNumber.from("598412000000000000000000"),ethers.BigNumber.from("591573000000000000000000"),ethers.BigNumber.from("587431000000000000000000"),ethers.BigNumber.from("542785000000000000000000"),ethers.BigNumber.from("536754000000000000000000"),ethers.BigNumber.from("518240000000000000000000"),ethers.BigNumber.from("511920000000000000000000"),ethers.BigNumber.from("452870000000000000000000")], ethers.BigNumber.from("100000000000000000000000000"));

    */
    function setUp() public {

        multiRolesAuthority = new MultiRolesAuthority(
            GOVERNANCE, Authority(address(0)) //set to governance when deployed
        );

        vaultConfigurationModule = new VaultConfigurationModule(address(this), Authority(address(0)));

        vaultInitializationModule = new VaultInitializationModule(
            vaultConfigurationModule,
            address(this),
            Authority(address(0))
        );

        underlying = ERC20(address(0x2602278EE1882889B946eb11DC0E810075650983));
        usdv = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

        aphra = new AphraToken(GOVERNANCE, address(multiRolesAuthority));
        gauges = new GaugeFactory();
        bribes = new BribeFactory();
        Ve = new veAPHRA(address(aphra), GOVERNANCE, address(multiRolesAuthority));
        Ve_dist = new ve_dist(address(Ve));
        voter = new Voter(address(Ve), address(gauges), address(bribes));
        minter = new Minter(address(voter), address(Ve), address(Ve_dist));

        //create airdrop
        airdropClaim = new AirdropClaim(0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55, address(Ve));

        vaultFactory = new VaultFactory(address(this), multiRolesAuthority);

        vaderGateway = new VaderGateway(
            address(VADER_MINTER),
            GOVERNANCE,
            multiRolesAuthority,
            address(underlying),
            address(usdv)
        );

        strategy1 = new USDVOverPegStrategy(
            underlying,
            GOVERNANCE,
            multiRolesAuthority,
            POOL,
            XVADER,
            address(vaderGateway),
            UNIROUTER,
            WETH
        );

        setupRolesCapabilities();

        Ve.setVoter(address(voter));
        Ve_dist.setDepositor(address(minter));
        //address[] memory _tokens, address _minter


        //setup partner mint storage
        //become the vader governance
        hevm.startPrank(
            address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9), address(0x76791a5aE935675DE187556C95a6Af1997C0633F)
        );
        //whitelist our vader gateway for minting usdv
        VADER_MINTER.whitelistPartner(
            address(vaderGateway), uint(0), uint256(5e24), uint256(5e24), uint(0)
        );
        hevm.stopPrank();

        giveTokens(address(underlying), 100_000_000e18);

        address dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        giveTokens(dai, 100_000_000e18);

        ERC20(dai).approve(POOL, type(uint256).max);

        printPeg();

        ICurve(POOL).exchange_underlying(1, int128(0), 500_000e18, uint(1));

        printPeg();
    }

    enum ROLES {
        MINTER,
        GOVERNANCE,
        VAULT_CONFIG,
        VAULT_INIT_MODULE,
        VAULT,
        STRATEGY,
        GAUGE,
        BRIBE,
        VOTER,
        VE,
        VE_DIST
    }

    function setupRolesCapabilities() internal {
        hevm.startPrank(
            GOVERNANCE, GOVERNANCE
        );
        //MINTER
        multiRolesAuthority.setUserRole(address(minter), uint8(ROLES.MINTER), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.MINTER), AphraToken.mint.selector, true);

        // VAULT CONFIG module permissions
        multiRolesAuthority.setUserRole(address(vaultConfigurationModule), uint8(ROLES.VAULT_CONFIG), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT_CONFIG), Vault.setFeePercent.selector, true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT_CONFIG), Vault.setHarvestDelay.selector, true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT_CONFIG), Vault.setHarvestWindow.selector, true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT_CONFIG), Vault.setTargetFloatPercent.selector, true);

        //vault init module permissions
        multiRolesAuthority.setUserRole(address(vaultInitializationModule), uint8(ROLES.VAULT_INIT_MODULE), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT_INIT_MODULE), Vault.initialize.selector, true);
        hevm.stopPrank();
    }
    function testDeploy() public {

        address[] memory initDepositAssets = new address[](2);
        initDepositAssets[0] = address(underlying);
        initDepositAssets[1] = address(usdv);
        voter.initialize(initDepositAssets, address(minter));//needs some init stuff
        //address[] memory claimants,
        //        uint[] memory amounts,
        //        uint max
        //andrew 2e18
        //tekka 1e18
        //ehjc 1e18
        //rohamanas 1e18
        //greenbergz 1e18
        //airdrop 3e18

        address[] memory initVe = new address[](5);
        initVe[0] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initVe[1] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initVe[2] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initVe[3] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initVe[4] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);

        uint256[] memory initVeAmount = new uint[](5);
        initVeAmount[0] = uint(1e18);
        initVeAmount[1] = uint(5e17);
        initVeAmount[2] = uint(5e17);
        initVeAmount[3] = uint(5e17);
        initVeAmount[4] = uint(5e17);

        address[] memory initToken = new address[](6);
        initToken[0] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initToken[1] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initToken[2] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initToken[3] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initToken[4] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);
        initToken[5] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);

        uint256[] memory initTokenAmount = new uint[](6);
        initTokenAmount[0] = uint(1e18);
        initTokenAmount[1] = uint(5e17);
        initTokenAmount[2] = uint(5e17);
        initTokenAmount[3] = uint(5e17);
        initTokenAmount[4] = uint(5e17);
        initTokenAmount[5] = uint(3e18);

        minter.initialize(initVe, initVeAmount, initVe, initTokenAmount,  uint(9e18));//needs some init stuff

        vaultConfigurationModule.setDefaultFeePercent(0.1e18);
        vaultConfigurationModule.setDefaultHarvestDelay(6 hours);
        vaultConfigurationModule.setDefaultHarvestWindow(5 minutes);
        vaultConfigurationModule.setDefaultTargetFloatPercent(0.01e18);

        //deploy and initialize vault
        Vault vault = vaultFactory.deployVault(underlying);
        vaultInitializationModule.initializeVault(vault);

        //setup setup strategy as a valid auth for the minter
        hevm.startPrank(GOVERNANCE, GOVERNANCE);
        multiRolesAuthority.setUserRole(address(strategy1), uint8(ROLES.STRATEGY), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.STRATEGY), vaderGateway.partnerMint.selector, true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.STRATEGY), vaderGateway.partnerBurn.selector, true);

        //setup vault as as a valid auth for the strategy minter
        multiRolesAuthority.setUserRole(address(vault), uint8(ROLES.VAULT), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT), strategy1.mint.selector, true);
        hevm.stopPrank();
    }

    function printPeg() internal {
        uint256 usdv_amount = ICurve(POOL).balances(0);
        uint256 tpool_amount = ICurve(POOL).balances(1);

        console.log("usdv", usdv_amount);
        console.log("3pool", tpool_amount);
        console.log("peg/1e3", tpool_amount * 1e3 / usdv_amount);
    }

    function giveTokens(address token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (ERC20(token).balanceOf(address(this)) == amount) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(token, keccak256(abi.encode(address(this), uint256(i))));
            hevm.store(token, keccak256(abi.encode(address(this), uint256(i))), bytes32(amount));
            if (ERC20(token).balanceOf(address(this)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(token, keccak256(abi.encode(address(this), uint256(i))), prevValue);
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function _buyUnderlyingFromUniswap(uint256 amount) internal {
        address[] memory path = new address[](2);

        path[0] = WETH;
        path[1] = address(underlying);

        uint256[] memory amounts = IUniswap(UNIROUTER).getAmountsOut(
            amount, path
        );

        uint256 amountOut = amounts[amounts.length - 1];

        IUniswap(UNIROUTER).swapETHForExactTokens{value : uint(5 ether)}(
            amountOut,
            path,
            address(this),
            block.timestamp
        );
    }


//        function testIntegration() public {
//            hevm.startPrank(
//                GOVERNANCE, GOVERNANCE
//            );
//            multiRolesAuthority.setUserRole(address(vaultConfigurationModule), 0, true);
//            multiRolesAuthority.setRoleCapability(0, Vault.setFeePercent.selector, true);
//            multiRolesAuthority.setRoleCapability(0, Vault.setHarvestDelay.selector, true);
//            multiRolesAuthority.setRoleCapability(0, Vault.setHarvestWindow.selector, true);
//            multiRolesAuthority.setRoleCapability(0, Vault.setTargetFloatPercent.selector, true);
//
//            multiRolesAuthority.setUserRole(address(vaultInitializationModule), 1, true);
//            multiRolesAuthority.setRoleCapability(1, Vault.initialize.selector, true);
//
//
//            vaultConfigurationModule.setDefaultFeePercent(0.1e18);
//            vaultConfigurationModule.setDefaultHarvestDelay(6 hours);
//            vaultConfigurationModule.setDefaultHarvestWindow(5 minutes);
//            vaultConfigurationModule.setDefaultTargetFloatPercent(0.01e18);
//
//            //deploy and initialize vault
//            Vault vault = vaultFactory.deployVault(underlying);
//            vaultInitializationModule.initializeVault(vault);
//
//            //setup setup strategy as a valid auth for the minter
//            multiRolesAuthority.setUserRole(address(strategy1), 2, true);
//            multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerMint.selector, true);
//            multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerBurn.selector, true);
//
//            //setup vault as as a valid auth for the strategy minter
//            multiRolesAuthority.setUserRole(address(vault), 3, true);
//            multiRolesAuthority.setRoleCapability(3, strategy1.mint.selector, true);
//            hevm.stopPrank();
//            uint256 treasury = 1_000_000e18;
//
//            underlying.approve(address(vault), type(uint256).max);
//            vault.deposit(treasury);
//            hevm.startPrank(
//                GOVERNANCE, GOVERNANCE
//            );
//            vault.trustStrategy(strategy1);
//            vault.depositIntoStrategy(strategy1, treasury);
//            vault.pushToWithdrawalStack(strategy1);
//
//            vaultConfigurationModule.setDefaultFeePercent(0.2e18);
//            assertEq(vault.feePercent(), 0.1e18);
//
//            vaultConfigurationModule.syncFeePercent(vault);
//            assertEq(vault.feePercent(), 0.2e18);
//
//            //peg arb swap to xvader
//            uint256 hitAmount = 80_000e18;
//            startMeasuringGas("strategy hit");
//            strategy1.hit(hitAmount, int128(1), new address[](0));
//            stopMeasuringGas();
//            hevm.stopPrank();
//
//            Strategy[] memory strategiesToHarvest = new Strategy[](1);
//            strategiesToHarvest[0] = strategy1;
//            startMeasuringGas("Vault Harvest");
//            vault.harvest(strategiesToHarvest);
//            stopMeasuringGas();
//
//            hevm.warp(block.timestamp + vault.harvestDelay());
//
//            printPeg();
//
//            //        vault.withdraw(1363636363636363636);
//            //        assertEq(vault.balanceOf(address(this)), 0);
//        }
}
