// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {VaderFuseOracle} from "../VaderFuseOracle.sol";
import {console} from "./console.sol";
contract VaderFuseOracleTest is DSTestPlus {

    VaderFuseOracle oracle;

    function setUp() public {
        oracle = new VaderFuseOracle();
    }

    function testOracle() public {
        uint vaderPrice = oracle.getUnderlyingPrice(oracle.VADER());
        console.log("Vader Price");
        console.log(vaderPrice);
        uint usdvPrice = oracle.getUnderlyingPrice(oracle.USDV());
        console.log("USDV Price");
        console.log(usdvPrice);
        uint xvaderPrice = oracle.getUnderlyingPrice(oracle.XVADER());
        console.log("xvaderPrice");
        console.log(xvaderPrice);
    }
}
