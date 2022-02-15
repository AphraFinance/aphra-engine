// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "../FixedPointMathLib.sol"; //added fdiv and fmul TODO: looking at new rari/next code perhaps we're moving to a new library
import {ERC20Strategy} from "../interfaces/Strategy.sol";
import {VaderGateway, IVaderMinter} from "../VaderGateway.sol";
import {IERC20, IUniswap, IXVader, ICurve} from "../interfaces/StrategyInterfaces.sol";

contract USDVUnderPegStrategy is Auth, ERC20("USDVUnderPegStrategy", "aUSDVUnderPegStrategy", 18), ERC20Strategy {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 public constant DAI = ERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));  //our flip
    ERC20 public constant USDC = ERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); //our flap
    ERC20 public constant USDT = ERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); //our flop
    ERC20 public constant USDV = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

    ERC20 public immutable WETH;
    ICurve public immutable POOL;
    IUniswap public immutable UNISWAP;
    IXVader public immutable XVADER;
    IVaderMinter public immutable VADERGATEWAY;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        address POOL_,
        address XVADER_,
        address VADERGATEWAY_,
        address UNIROUTER_,
        address WETH_
    ) Auth(GOVERNANCE_, AUTHORITY_) { //set authority to something that enables operators for aphra
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10**UNDERLYING_.decimals();

        POOL = ICurve(POOL_);
        XVADER = IXVader(XVADER_);

        VADERGATEWAY = IVaderMinter(VADERGATEWAY_); // our partner minter
        UNISWAP = IUniswap(UNIROUTER_);
        WETH = ERC20(WETH_);

        USDV.safeApprove(POOL_, type(uint256).max); //set unlimited approval to the pool for usdv
        DAI.safeApprove(UNIROUTER_, type(uint256).max);
        USDC.safeApprove(UNIROUTER_, type(uint256).max);
        USDT.safeApprove(UNIROUTER_, type(uint256).max);
        WETH.safeApprove(UNIROUTER_, type(uint256).max); //prob not needed
        UNDERLYING.safeApprove(XVADER_, type(uint256).max);
        UNDERLYING.safeApprove(VADERGATEWAY_, type(uint256).max);
    }

    /* //////////////////////////////////////////////////////////////
                             STRATEGY LOGIC
    ///////////////////////////////////////////////////////////// */


    function hit(uint256 uAmount_, int128 enterCoin_, address[] memory path_) external requiresAuth () {
        uint vAmount = VADERGATEWAY.partnerBurn(uAmount_, uint(1));
        uint uAmount = _swapToUnderlying(vAmount, enterCoin_, path_);
        require(uAmount > uAmount_, "Failed to arb for profit");
    unchecked {
        require( POOL.balances(1) * 1e3 / (POOL.balances(0)) <= 1e3, "peg must be at or below 1");
    }
    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function ethToUnderlying(uint256 ethAmount_) external view returns (uint256) {
        if (ethAmount_ == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(UNDERLYING);
        uint256[] memory amounts = UNISWAP.getAmountsOut(ethAmount_, path);

        return amounts[amounts.length - 1];
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external requiresAuth override returns (uint256) {
        _mint(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));

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


    function _swapToUnderlying(uint vAmountIn_, int128 enterCoin_, address[] memory path_) internal returns (uint oAmount) {


        //we have vader, we want to get usdv, so we need dai/usdc/usdt first

        //get best exit address
        //get mins for swap

        address enterCoinAddress = address(DAI);
        if (enterCoin_ == int128(2)) {
            enterCoinAddress = address(USDC);
        } else if (enterCoin_ == int128(3)) {
            enterCoinAddress = address(USDT);
        }


        address[] memory path;
        if(path_.length == 0) {
            path = new address[](3);
            path[0] = address(UNDERLYING);
            path[1] = address(WETH);
            path[2] = enterCoinAddress; //vader eth pool has the best depth for vader
        } else {
            path = path_;
        }

        uint256[] memory amounts = UNISWAP.getAmountsOut(vAmountIn_, path);
        uint256 swapOut = amounts[amounts.length - 1];

        UNISWAP.swapExactTokensForTokens(
            vAmountIn_,
            swapOut,
            path,
            address(this),
            block.timestamp
        );
        uint256 usdvBalanceBefore;
        unchecked {
            usdvBalanceBefore = USDV.balanceOf(address(this));
        }

        POOL.exchange_underlying(enterCoin_, int128(0), swapOut, uint(1));

        unchecked {
            oAmount = USDV.balanceOf(address(this)) - usdvBalanceBefore;
        }

    }

    function _exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        unchecked {
            underlyingBalance = UNDERLYING.balanceOf(address(this));
        }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }
}

