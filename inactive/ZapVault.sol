// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.11;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/auth/Auth.sol";
import {Vault} from "./Vault.sol";
import "SafeMath.sol";
import "ERC20.sol";
import "ReentrancyGuard.sol";
import "./Gauges.sol";

contract ZapGauge is Auth, ReentrancyGuard {
    using SafeMath for uint;

    event Pause(bool _paused);

    bool public paused;

    // 0x2602278EE1882889B946eb11DC0E810075650983
    ERC20 public immutable underlying;

    Vault public immutable vault;

    Gauge public gauge;

    constructor(
        address underlying,
        address _vault,
        address _gauge
    ) {
        underlying = ERC20(underlying);
        vault = Vault(_vault);

        ERC20(vault).safeApprove(_gauge, type(uint).max);
    }

    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function pause() external requiresAuth whenNotPaused {
        paused = true;
        emit Pause(true);
    }

    function unpause() external requiresAuth whenPaused {
        paused = false;
        emit Pause(false);
    }

    function depositIntoVaultGaugeForCaller(
        Vault vault,
        ERC20 underlying,
        uint256 amount,
        uint256 veTokenId
    ) internal {
        // Approve the underlying tokens to the Vault.
        underlying.safeApprove(address(vault), amount);

        // Deposit the underlying tokens into the Vault.
        vault.deposit(amount);

        // Transfer the newly minted rvTokens back to the caller.
//        ERC20(vault).safeTransfer(msg.sender, vault.balanceOf(address(this)));
        gauge.deposit(amount, veTokenId);
    }

    function _depositGauge() internal {

    }

    function zap(uint _depositAmount, uint _veTokenId) external nonReentrant whenNotPaused {



        //deposit into vault and then into gauge

        // reserve 0 = Vader
        (uint reserve0, , ) = pair.getReserves();
        uint ethSwapAmount = _calculateSwapInAmount(reserve0, msg.value);

        // swap ETH to Vader
        uint vaderOut = _swap(ethSwapAmount);

        // add liquidity
        uint ethIn = msg.value.sub(ethSwapAmount);
        (uint amountVader, uint amountEth, uint lp) = router.addLiquidityETH{
        value: ethIn
        }(address(underlying), vaderOut, 1, 1, address(this), block.timestamp);

        // refund Vader
        if (amountVader < vaderOut) {
            underlying.transfer(msg.sender, vaderOut - amountVader);
        }
        // refund ETH
        if (amountEth < ethIn) {
            (bool ok, ) = msg.sender.call{value: ethIn - amountEth}("");
            require(ok, "refund ETH failed");
        }

        // deposit LP for bond
        uint payout = bond.deposit(lp, type(uint).max, msg.sender);
        require(payout >= minPayout, "payout < min");
    }

    function recover(address _token) external requiresAuth {
        if (_token != address(0)) {
            ERC20(_token).transfer(
                msg.sender,
                ERC20(_token).balanceOf(address(this))
            );
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}
