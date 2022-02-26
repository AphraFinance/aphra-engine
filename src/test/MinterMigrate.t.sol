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
import {Minter} from "../Minter.sol";
import {MinterV2} from "../MinterV2.sol";
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


contract MinterMigrateTest is DSTestPlus {

    function setUp() public {


    }

    function testMigrate() public {

        Minter current = Minter(0x2D58452188703d19c5a7f00C3DEE7457F2a4CAB6);
        MinterV2 next = new MinterV2(
            0x2101a22A8A6f2b60eF36013eFFCef56893cea983,
            0xcbb46b017e8d785C107e97c56135894b3eAD599C,
            0x42Fd5B17D55F243c3fF28a38bb49bcCbEf48a7B0,
            0x6f5A22E1508410E40bFeCf3B18Bc9DcC143Ed906,
            0xc2D329f73493dBC4e2E52C11f9499a379300dc35,
            0xB8c93312FaE3F881E82632260fB7e9b4b15C4520
        );
        hevm.startPrank(0x2101a22A8A6f2b60eF36013eFFCef56893cea983, 0x2101a22A8A6f2b60eF36013eFFCef56893cea983);

        current.tokenMigrateMinter(address(next));
        current.ve_distMigrateDepositor(address(next));
        current.voterMigrateMinter(address(next));
    }


}
