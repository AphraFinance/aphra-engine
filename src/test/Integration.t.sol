// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Authority} from "solmate/auth/Auth.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MultiRolesAuthority} from "solmate/auth/authorities/MultiRolesAuthority.sol";

import {USDVOverPegStrategy} from "../USDVOverPegStrategy.sol";

import {VaultInitializationModule} from "../modules/VaultInitializationModule.sol";
import {VaultConfigurationModule} from "../modules/VaultConfigurationModule.sol";

import {Strategy} from "../interfaces/Strategy.sol";

import {Vault} from "../Vault.sol";
import {VaultFactory} from "../VaultFactory.sol";

contract IntegrationTest is DSTestPlus {
    VaultFactory vaultFactory;

    MultiRolesAuthority multiRolesAuthority;

    VaultConfigurationModule vaultConfigurationModule;

    VaultInitializationModule vaultInitializationModule;

    MockERC20 underlying;

    USDVOverPegStrategy strategy1;
    function setUp() public {
        underlying = new MockERC20("Mock Vader", "VADER", 18);

        multiRolesAuthority = new MultiRolesAuthority(address(this), Authority(address(0)));

        vaultFactory = new VaultFactory(address(this), multiRolesAuthority);

        vaultConfigurationModule = new VaultConfigurationModule(address(this), Authority(address(0)));

        //run on a fork
        vaultInitializationModule = new VaultInitializationModule(
            vaultConfigurationModule,
            address(this),
            Authority(address(0))
        );

        address GOVERNANCE = address(0x2101a22A8A6f2b60eF36013eFFCef56893cea983);
        address POOL =  address(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
        address FACTORY =  address(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
        address XVADER =  address(0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369);
        address VADERGATEWAY =  address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //needs deploy with vader ecosystem, for now fork and override with hevm
        address UNIROUTER =  address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address WETH =  address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        strategy1 = new USDVOverPegStrategy(
        underlying,
        GOVERNANCE,
        POOL,
        FACTORY,
        XVADER,
        VADERGATEWAY,
        UNIROUTER,
        WETH
        );
    }

    function testIntegration() public {
        multiRolesAuthority.setUserRole(address(vaultConfigurationModule), 0, true);
        multiRolesAuthority.setRoleCapability(0, Vault.setFeePercent.selector, true);
        multiRolesAuthority.setRoleCapability(0, Vault.setHarvestDelay.selector, true);
        multiRolesAuthority.setRoleCapability(0, Vault.setHarvestWindow.selector, true);
        multiRolesAuthority.setRoleCapability(0, Vault.setTargetFloatPercent.selector, true);

        multiRolesAuthority.setUserRole(address(vaultInitializationModule), 1, true);
        multiRolesAuthority.setRoleCapability(1, Vault.initialize.selector, true);

        vaultConfigurationModule.setDefaultFeePercent(0.1e18);
        vaultConfigurationModule.setDefaultHarvestDelay(6 hours);
        vaultConfigurationModule.setDefaultHarvestWindow(5 minutes);
        vaultConfigurationModule.setDefaultTargetFloatPercent(0.01e18);

        Vault vault = vaultFactory.deployVault(underlying);
        vaultInitializationModule.initializeVault(vault);

        underlying.mint(address(this), 1.5e18);

        underlying.approve(address(vault), 1e18);
        vault.deposit(1e18);

        vault.trustStrategy(strategy1);
        vault.depositIntoStrategy(strategy1, 0.5e18);
        vault.pushToWithdrawalStack(strategy1);

        vaultConfigurationModule.setDefaultFeePercent(0.2e18);
        assertEq(vault.feePercent(), 0.1e18);

        vaultConfigurationModule.syncFeePercent(vault);
        assertEq(vault.feePercent(), 0.2e18);

        //peg arb swap to xvader
        underlying.transfer(address(strategy1), 0.25e18);

        Strategy[] memory strategiesToHarvest = new Strategy[](1);
        strategiesToHarvest[0] = strategy1;

        vault.harvest(strategiesToHarvest);

        hevm.warp(block.timestamp + vault.harvestDelay());

        vault.withdraw(1363636363636363636);
        assertEq(vault.balanceOf(address(this)), 0);
    }
}
