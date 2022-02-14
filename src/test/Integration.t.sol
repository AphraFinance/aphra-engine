// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
//import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
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
import "./console.sol";


interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Set block.basefee (newBasefee)
    function fee(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address, bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address, bytes32, bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256, bytes32) external returns (uint8, bytes32, bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address, address) external;
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
    function expectEmit(bool, bool, bool, bool) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address, bytes calldata, bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address, bytes calldata) external;

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
    address constant POOL = address(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
    address constant FACTORY = address(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
    address constant XVADER = address(0x665ff8fAA06986Bd6f1802fA6C1D2e7d780a7369);
    address constant UNIROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IVaderMinterExtended constant VADER_MINTER = IVaderMinterExtended(0x00aadC47d91fD9CaC3369E6045042f9F99216B98);

    IVaderMinter vaderGateway;


    function setUp() public {
        underlying = ERC20(address(0x2602278EE1882889B946eb11DC0E810075650983));
        usdv = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

        multiRolesAuthority = new MultiRolesAuthority(
            address(this), Authority(address(0)) //set to governance when deployed
        );

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

        giveTokens(address(underlying), 100_000_000e18);

        address dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        giveTokens(dai, 100_000_000e18);

        ERC20(dai).approve(POOL, type(uint256).max);

        printPeg();

        ICurve(POOL).exchange_underlying(1, int128(0), 500_000e18, uint(1));

        printPeg();
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

        //deploy and initialize vault
        Vault vault = vaultFactory.deployVault(underlying);
        vaultInitializationModule.initializeVault(vault);

        //setup setup strategy as a valid auth for the minter
        multiRolesAuthority.setUserRole(address(strategy1), 2, true);
        multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerMint.selector, true);
        multiRolesAuthority.setRoleCapability(2, vaderGateway.partnerBurn.selector, true);

        //setup vault as as a valid auth for the strategy minter
        multiRolesAuthority.setUserRole(address(vault), 3, true);
        multiRolesAuthority.setRoleCapability(3, strategy1.mint.selector, true);

        uint256 treasury = 1_000_000e18;

        underlying.approve(address(vault), type(uint256).max);
        vault.deposit(treasury);

        vault.trustStrategy(strategy1);
        vault.depositIntoStrategy(strategy1, treasury);
        vault.pushToWithdrawalStack(strategy1);

        vaultConfigurationModule.setDefaultFeePercent(0.2e18);
        assertEq(vault.feePercent(), 0.1e18);

        vaultConfigurationModule.syncFeePercent(vault);
        assertEq(vault.feePercent(), 0.2e18);

        //peg arb swap to xvader
        hevm.startPrank(GOVERNANCE, GOVERNANCE);
        uint256 hitAmount = 80_000e18;
        startMeasuringGas("strategy hit");
        strategy1.hit(hitAmount, int128(1), new address[](0));
        stopMeasuringGas();
        hevm.stopPrank();
        Strategy[] memory strategiesToHarvest = new Strategy[](1);
        strategiesToHarvest[0] = strategy1;
        startMeasuringGas("Vault Harvest");
        vault.harvest(strategiesToHarvest);
        stopMeasuringGas();

        hevm.warp(block.timestamp + vault.harvestDelay());

        printPeg();

        //        vault.withdraw(1363636363636363636);
        //        assertEq(vault.balanceOf(address(this)), 0);
    }
}
