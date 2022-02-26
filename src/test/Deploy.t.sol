// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {Auth, Authority} from "solmate/auth/Auth.sol";
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
import {GaugeFactory, Gauge} from "../Gauge.sol";
import {BribeFactory, Bribe} from "../Bribe.sol";
import {veAPHRA} from "../veAPHRA.sol";
import {ve_dist} from "../ve_dist.sol";
import {Minter} from "../Minter.sol";
import {Voter} from "../Voter.sol";
import {AphraToken} from "../AphraToken.sol";
import {AirdropClaim} from "../AirdropClaim.sol";
import "./console.sol";
enum ROLES {
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


contract DeployTest is DSTestPlus {
    VaultFactory vaultFactory;

    MultiRolesAuthority multiRolesAuthority;

    VaultConfigurationModule vaultConfigurationModule;

    VaultInitializationModule vaultInitializationModule;

    ERC20 vader;

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

        vader = ERC20(address(0x2602278EE1882889B946eb11DC0E810075650983));
        usdv = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

        aphra = new AphraToken();
        gauges = new GaugeFactory();
        bribes = new BribeFactory();
        Ve = new veAPHRA(
            address(aphra),
            GOVERNANCE,
            address(multiRolesAuthority)
        );
        Ve_dist = new ve_dist(
            address(Ve)
        );
        voter = new Voter(
            GOVERNANCE,
            address(multiRolesAuthority),
            address(Ve),
            address(gauges),
            address(bribes)
        );
        minter = new Minter(
            GOVERNANCE,
            address(multiRolesAuthority),
            address(voter),
            address(Ve),
            address(Ve_dist)
        );

        //create airdrop
        airdropClaim = new AirdropClaim(
            GOVERNANCE,
                0xd0aa6a4e5b4e13462921d7518eebdb7b297a7877d6cfe078b0c318827392fb55, //alice test key
            address(Ve)
        );

        vaultFactory = new VaultFactory(
            address(this),
            multiRolesAuthority
        );

        vaderGateway = new VaderGateway(
            address(VADER_MINTER),
            GOVERNANCE,
            multiRolesAuthority,
            address(vader),
            address(usdv)
        );

        strategy1 = new USDVOverPegStrategy(
            vader,
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
    }



    function setupRolesCapabilities() internal {
        hevm.startPrank(
            GOVERNANCE, GOVERNANCE
        );

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
    address ALICE = address(0x185a4dc360CE69bDCceE33b3784B0282f7961aea);
    function testInitialize() public {

        address[] memory initDepositAssets = new address[](2);
        initDepositAssets[0] = address(vader);
        initDepositAssets[1] = address(usdv);
        voter.initialize(initDepositAssets, address(minter));

        address[] memory initVe = new address[](1);
        initVe[0] = address(0x86d3ee9ff0983Bc33b93cc8983371a500f873446);

        uint256[] memory initVeAmount = new uint[](1);
        initVeAmount[0] = uint(2_000_000e18);

        address[] memory initToken = new address[](2);
        initToken[0] = address(GOVERNANCE);
        initToken[1] = address(airdropClaim);

        uint256[] memory initTokenAmount = new uint[](2);
        initTokenAmount[0] = uint(30_500_000e18);
        initTokenAmount[1] = uint(3_000_000e18);

        aphra.setMinter(address(minter));
        minter.initialize(initVe, initVeAmount, initToken, initTokenAmount, uint(50_000_000e18));

        bytes32[] memory aliceProof = new bytes32[](1);
        aliceProof[0] = 0xceeae64152a2deaf8c661fccd5645458ba20261b16d2f6e090fe908b0ac9ca88;
        airdropClaim.claim(address(ALICE), 100e18, aliceProof);

        giveTokens(address(vader), uint(100000e18), address(ALICE));

        hevm.startPrank(address(ALICE), address(ALICE));
        Gauge newGauge = Gauge(voter.createGauge(address(vader))); //avVADER

        vader.approve(address(newGauge), type(uint).max);

        newGauge.deposit(uint(1000e18), 2);
        int256[] memory votes = new int256[](1);
        votes[0] = int256(2);
        address[] memory voteAddr = new address[](1);
        voteAddr[0] = address(vader);

        address[] memory tokens = new address[](1);
        tokens[0] = address(aphra);

        uint week = 86400 * 7;

        voter.vote(2, voteAddr, votes);
        hevm.warp(minter.active_period() + week + 1);
        minter.update_period();
        voter.distro();
        emit log_string("ALICE Earned Week 1");
        emit log_uint(newGauge.earned(address(aphra), ALICE));
        hevm.warp(minter.active_period() + week + 1);
        minter.update_period();
        voter.distro();
        emit log_string("ALICE Earned Week 2");
        emit log_uint(newGauge.earned(address(aphra), ALICE));
        hevm.warp(minter.active_period() + week + 1);
        minter.update_period();
        voter.distro();
        emit log_string("ALICE Earned Week 3");
        emit log_uint(newGauge.earned(address(aphra), ALICE));
        hevm.warp(minter.active_period() + week + 1);
        minter.update_period();
        voter.distro();
        hevm.startPrank(GOVERNANCE, GOVERNANCE);
        aphra.transfer(ALICE, uint(1_000e18));
        emit log_string("Unlock veAPHRA");
        Ve.unlock();
        hevm.stopPrank();
        hevm.warp(minter.active_period() + week + 1);
        emit log_string("ALICE Earned Week 4");
        emit log_uint(newGauge.earned(address(aphra), ALICE));
        emit log_string("ve_dist ALICE NFT 2 claimable");
        emit log_uint(Ve_dist.claimable(uint(2)));
        Ve_dist.claim(uint(2));
        emit log_string("ALICE NFT 2 after ve dist claim");
        emit log_uint(Ve.balanceOfNFT(uint(2)));
        hevm.startPrank(ALICE, ALICE);

        newGauge.getReward(address(ALICE), tokens);
        emit log_string("TEAM NFT 1 after Reward Claim");
        emit log_uint(Ve.balanceOfNFT(uint(2)));

        Ve_dist.claim(uint(1));
        emit log_string("veAPHRA NFT 1 Balance 1");
        emit log_uint(Ve.balanceOfNFT(uint(1)));


        assertEq(aphra.totalSupply(), 50_000_000e18);

    }


    function setupVaults() internal {
        vaultConfigurationModule.setDefaultFeePercent(0.1e18);
        vaultConfigurationModule.setDefaultHarvestDelay(6 hours);
        vaultConfigurationModule.setDefaultHarvestWindow(5 minutes);
        vaultConfigurationModule.setDefaultTargetFloatPercent(0.01e18);

        //deploy and initialize vault
        Vault vault = vaultFactory.deployVault(vader);
        vaultInitializationModule.initializeVault(vault);

        //setup setup strategy as a valid auth for the minter
        hevm.startPrank(GOVERNANCE, GOVERNANCE);
        multiRolesAuthority.setUserRole(address(strategy1), uint8(ROLES.STRATEGY), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.STRATEGY), vaderGateway.partnerMint.selector, true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.STRATEGY), vaderGateway.partnerBurn.selector, true);

        //setup vault as as a valid auth for the strategy minter
        multiRolesAuthority.setUserRole(address(vault), uint8(ROLES.VAULT), true);
        multiRolesAuthority.setRoleCapability(uint8(ROLES.VAULT), strategy1.mint.selector, true);
    }


    function giveTokens(address token, uint256 amount, address to) internal {
        // Edge case - balance is already set for some reason
        if (ERC20(token).balanceOf(to) == amount) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(token, keccak256(abi.encode(address(to), uint256(i))));
            hevm.store(token, keccak256(abi.encode(address(to), uint256(i))), bytes32(amount));
            if (ERC20(token).balanceOf(address(to)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(token, keccak256(abi.encode(address(to), uint256(i))), prevValue);
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

}
