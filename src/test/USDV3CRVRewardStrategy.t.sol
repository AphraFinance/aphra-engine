// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Authority} from "solmate/auth/Auth.sol";
import {MultiRolesAuthority} from "../MultiRolesAuthority.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IRewards, USDV3CRVRewardStrategy} from "../strategies/USDV3CRVRewardStrategy.sol";

import "./console.sol";
import {Gauge} from "../Gauge.sol";
import {Bribe} from "../Bribe.sol";

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

interface ICurve {
    function get_virtual_price() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function add_liquidity(uint256[2] memory deposit, uint256 min) external returns (uint256);

    function balances(uint256) external view returns (uint256);
}

interface IRewards2 {
    function notifyRewardAmount(uint amount) external;
    function earned(address account) external view returns (uint);
    function setRewardsDuration(uint _rewardsDuration) external;
}


contract USDV3CRVRewardStrategyTest is DSTestPlus {
    USDV3CRVRewardStrategy strategy;

    address constant POOL = address(0x7abD51BbA7f9F6Ae87aC77e1eA1C5783adA56e5c);
    address constant USDV = address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe);
    address constant VADER = address(0x2602278EE1882889B946eb11DC0E810075650983);

    function setUp() public {
        MultiRolesAuthority multiRolesAuthority = new MultiRolesAuthority(
            address(this), Authority(address(0)) //set to governance when deployed
        );

        strategy = new USDV3CRVRewardStrategy(
            ERC20(POOL),
            address(this),
            multiRolesAuthority,
            IRewards(0x2413e4594aadE7513AB6Dc43209D4C312cC35121),
            Gauge(0xEA7aD26d1B722518F7a9Af4E75eFAF8DfD042034),
            Bribe(0xA4d1aD4325eF52b76495d52B79402e91961931d5)
        );

        //acquire vader for the test harness
        //setup partner mint storage
        //become the vader governance
        // hevm.startPrank(
        //     address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9), address(0x76791a5aE935675DE187556C95a6Af1997C0633F)
        // );
        // //whitelist our vader gateway for minting usdv
        // VADER_MINTER.whitelistPartner(
        //     address(vaderGateway), uint(0), uint256(5e24), uint256(5e24), uint(0)
        // );
        // hevm.stopPrank();

        // giveTokens(address(underlying), 100_000_000e18);

        // address dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

        // giveTokens(dai, 100_000_000e18);

        // ERC20(dai).approve(POOL, type(uint256).max);

        // printPeg();

        // ICurve(POOL).exchange_underlying(1, int128(0), 3_000_000e18, uint(1));

        // printPeg();
    }

    function giveTokens(address recipient, address token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (ERC20(token).balanceOf(recipient) == amount) return;

        for (int256 i = 0; i < 100; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(token, keccak256(abi.encode(recipient, uint256(i))));
            hevm.store(token, keccak256(abi.encode(recipient, uint256(i))), bytes32(amount));
            if (ERC20(token).balanceOf(recipient) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(token, keccak256(abi.encode(recipient, uint256(i))), prevValue);
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

     function testIntegration() public {
         uint256 amt = 1_000_000e18;
        
        giveTokens(address(this), USDV, amt);
        address REWARDS = address(strategy.REWARDS());
        
        hevm.startPrank(address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9), address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9));
        giveTokens(address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9), VADER, amt*2);
        // ERC20(VADER).approve(REWARDS, type(uint256).max);
        
        ERC20(VADER).transfer(REWARDS, amt*2);
        IRewards2(REWARDS).notifyRewardAmount(amt);
        hevm.stopPrank();

        uint256[2] memory liq = [amt,0];

        ERC20(USDV).approve(POOL, type(uint256).max);
        uint256 crvAmt = ICurve(POOL).add_liquidity(liq, 0);
        
        ERC20(POOL).approve(address(strategy), type(uint256).max);
        
        strategy.mint(crvAmt);

        hevm.warp(1646399561);

        hevm.startPrank(address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9), address(0xFd9aD7F8B72fC133543Cb7cCC2F11C03b81726f9));
        IRewards2(REWARDS).notifyRewardAmount(amt);
        hevm.stopPrank();


        hevm.warp(1646399561 + 7*24*3600);

        uint256 earned = IRewards2(REWARDS).earned(address(strategy));

        console.log(earned);

        strategy.harvestRewards();


     }
}
