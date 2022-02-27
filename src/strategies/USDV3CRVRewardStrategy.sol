pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "../FixedPointMathLib.sol";
import {ERC20Strategy} from "../interfaces/Strategy.sol";
import {Gauge} from "../Gauge.sol";
import {Bribe} from "../Bribe.sol";
import {Vault} from "../Vault.sol";

interface IRewards {
    function rewardsToken() external view returns (address);
    function exit() external;
    function claimReward() external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function earned(address director) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address director) external view returns (uint256);
}
library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
}

contract USDV3CRVRewardStrategy is Auth, ERC20("USDV3CRVRewardStrategy", "aUSDV3CRVRewardStrategy", 18), ERC20Strategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    IRewards public immutable REWARDS;

    Gauge public gauge;
    Bribe public bribe;

    uint harvestCost = 80;
    uint harvestBase = 100;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address REWARDS_,
        address GAUGE_,
        address BRIBE_
    ) Auth(GOVERNANCE_, AUTHORITY_) { //set authority to something that enables operators for aphra
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10e18;
        REWARDS = IRewards(REWARDS_);
        bribe = Bribe(BRIBE_);
        gauge = Gauge(GAUGE_);
        UNDERLYING.safeApprove(REWARDS_, type(uint256).max);
    }

    function setGaugeBribe(Gauge newGauge_, Bribe newBribe_) external requiresAuth {
        bribe = newBribe_;
        gauge = newGauge_;
    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external requiresAuth override returns (uint256) {
        _mint(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        _stakeUnderlying(UNDERLYING.balanceOf(address(this)));
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));

        if (UNDERLYING.balanceOf(address(this)) < amount) {
            uint leaveAmount = amount - UNDERLYING.balanceOf(address(this));
            _unstakeUnderlying(leaveAmount);
        }
        UNDERLYING.safeTransfer(msg.sender, amount);

        return 0;
    }

    function balanceOfUnderlying(address user) external view override returns (uint256) {
        return balanceOf[user].fmul(_exchangeRate(), BASE_UNIT);
    }

    /* //////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    ///////////////////////////////////////////////////////////// */

    ERC20 internal immutable UNDERLYING;

    uint256 internal immutable BASE_UNIT;

    function _stakeUnderlying(uint amount) internal {
        REWARDS.stake(amount);
    }

    function _unstakeUnderlying(uint amount) internal {
        REWARDS.withdraw(amount);
    }

    function _computeStakedUnderlying() internal view returns (uint256) {
        return REWARDS.balanceOf(address(this));
    }

    function _exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        uint stakedBalance = _computeStakedUnderlying();
    unchecked {
        underlyingBalance = UNDERLYING.balanceOf(address(this)) + stakedBalance;
    }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }

    function emergencyDevWithdraw(address token, address to) external requiresAuth {
        ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)));
    }


    function harvestRewards() external {
        //get rewards
        REWARDS.claimReward();
        ERC20 rewardToken = ERC20(REWARDS.rewardsToken());
        //calc treasuryDeposit
        uint treasuryDeposit = rewardToken.balanceOf(address(this)) * harvestCost / harvestBase;
        //transfer to owner(treasury)
        rewardToken.transfer(owner, treasuryDeposit);

        //calc gauge deposit
        uint gaugeDeposit = (rewardToken.balanceOf(address(this)) - treasuryDeposit) / 2;

        //notify gauge
        rewardToken.safeApprove(address(gauge), gaugeDeposit);
        gauge.notifyRewardAmount(address(rewardToken), gaugeDeposit);
        //calc bribe deposit
        uint bribeDeposit = Math.max(gaugeDeposit, rewardToken.balanceOf(address(this)));
        //notify bribe
        rewardToken.safeApprove(address(bribe), bribeDeposit);
        bribe.notifyRewardAmount(address(rewardToken), bribeDeposit);
    }
}
