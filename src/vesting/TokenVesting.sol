// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

interface ve {
    function isUnlocked() external view returns (bool);
}

interface IVestingFactory {
    function getVe() external view returns (address);
}

/**
 * @title TokenVesting
 * @dev This contract handles the vesting of ERC20 tokens for a given beneficiary. Custody of multiple tokens
 * can be given to this contract, which will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * Any token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract TokenVesting is Auth {
    using SafeTransferLib for ERC20;

    event ERC20Released(address indexed token, uint amount);

    mapping(address => uint) private _erc20Released;
    address private immutable _beneficiary;
    uint private immutable _start;
    uint private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint startTimestamp,
        uint durationSeconds
    ) Auth(msg.sender, Authority(address(0))) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    function reclaimUnderlying(ERC20 token, address destination) external requiresAuth {
        uint reclaim = token.balanceOf(address(this)) - (vestedAmount(address(token), block.timestamp) - released(address(token)));
        token.safeTransfer(destination, reclaim);
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }



    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address token) public virtual {
        uint256 releasable = vestedAmount(token, block.timestamp) - released(token);
        _erc20Released[token] += releasable;
        emit ERC20Released(token, releasable);
        ERC20(token).safeTransfer(beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(ERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amout vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint timestamp) internal view virtual returns (uint256) {

        if (!ve(IVestingFactory(owner).getVe()).isUnlocked()) {
            return 0;
        } else if (timestamp >= start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
