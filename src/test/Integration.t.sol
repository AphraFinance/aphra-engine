// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Authority} from "solmate/auth/Auth.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
//import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MultiRolesAuthority} from "solmate/auth/authorities/MultiRolesAuthority.sol";

import {IVaderMinter, IUniswap, USDVOverPegStrategy, VaderGateway} from "../USDVOverPegStrategy.sol";
import {IVaderMinterExtended} from "../interfaces/vader/IVaderMinterExtended.sol";
import {VaultInitializationModule} from "../modules/VaultInitializationModule.sol";
import {VaultConfigurationModule} from "../modules/VaultConfigurationModule.sol";

import {Strategy} from "../interfaces/Strategy.sol";

import {Vault} from "../Vault.sol";
import {VaultFactory} from "../VaultFactory.sol";
import "./console.sol";

interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Set block.basefee (newBasefee)
    function fee(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address,address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address,address) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    // Record all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool,bool,bool,bool) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address,bytes calldata) external;

    function getCode(string calldata) external returns (bytes memory);
}


contract IntegrationTest is DSTestPlus {
    VaultFactory vaultFactory;

    MultiRolesAuthority multiRolesAuthority;

    VaultConfigurationModule vaultConfigurationModule;

    VaultInitializationModule vaultInitializationModule;

    ERC20 underlying;

    ERC20 usdv;
    USDVOverPegStrategy strategy1;

    address constant GOVERNANCE = address(0x2101a22A8A6f2b60eF36013eFFCef56893cea983);
    address constant POOL =  address(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
    address constant FACTORY =  address(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
    address constant XVADER =  address(0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369);
    address constant UNIROUTER =  address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IVaderMinterExtended constant VADER_MINTER = IVaderMinterExtended(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);

    IVaderMinter vaderGateway;

    function setUp() public {
        underlying = ERC20(address(0x2602278EE1882889B946eb11DC0E810075650983));
        usdv = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

        multiRolesAuthority = new MultiRolesAuthority(address(this), Authority(address(0)));

        vaultFactory = new VaultFactory(address(this), multiRolesAuthority);

        vaultConfigurationModule = new VaultConfigurationModule(address(this), Authority(address(0)));

        vaultInitializationModule = new VaultInitializationModule(
            vaultConfigurationModule,
            address(this),
            Authority(address(0))
        );

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

        //acquire vader for the test harness
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
        hevm.deal(address(this), uint(100 ether));
        _buyUnderlyingFromUniswap();//buy 5 eth worth of vader from uniswap
    }

    function _buyUnderlyingFromUniswap() internal {
        address[] memory path = new address[](2);

        path[0] = WETH;
        path[1] = address(underlying);

        uint256[] memory amounts = IUniswap(UNIROUTER).getAmountsOut(
            uint(5 ether), path
        );
        uint256 amountOut = amounts[amounts.length - 1];

        IUniswap(UNIROUTER).swapETHForExactTokens{value:uint(5 ether)}(
            amountOut,
            path,
            address(this),
            block.timestamp
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



        //setup governance as the caller for the strategy needs
        multiRolesAuthority.setUserRole(address(strategy1), 2, true);
        multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerMint.selector, true);
        multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerBurn.selector, true);



        vaultConfigurationModule.setDefaultFeePercent(0.1e18);
        vaultConfigurationModule.setDefaultHarvestDelay(6 hours);
        vaultConfigurationModule.setDefaultHarvestWindow(5 minutes);
        vaultConfigurationModule.setDefaultTargetFloatPercent(0.01e18);

        Vault vault = vaultFactory.deployVault(underlying);
        vaultInitializationModule.initializeVault(vault);

        underlying.approve(address(vault), type(uint256).max);
        vault.deposit(90000e18);

        vault.trustStrategy(strategy1);
        vault.depositIntoStrategy(strategy1, 90000e18);
        vault.pushToWithdrawalStack(strategy1);

        vaultConfigurationModule.setDefaultFeePercent(0.2e18);
        assertEq(vault.feePercent(), 0.1e18);

        vaultConfigurationModule.syncFeePercent(vault);
        assertEq(vault.feePercent(), 0.2e18);

        //peg arb swap to xvader
        hevm.startPrank(GOVERNANCE, GOVERNANCE);
        startMeasuringGas("strategy hit");
        strategy1.hit(uint(800e18), int128(1), new address[](0));
        stopMeasuringGas();
        hevm.stopPrank();
        Strategy[] memory strategiesToHarvest = new Strategy[](1);
        strategiesToHarvest[0] = strategy1;

        vault.harvest(strategiesToHarvest);

        hevm.warp(block.timestamp + vault.harvestDelay());

//        vault.withdraw(1363636363636363636);
//        assertEq(vault.balanceOf(address(this)), 0);
    }
}
