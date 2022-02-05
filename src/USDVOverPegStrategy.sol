// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {IVaderMinter} from "./interfaces/vader/IVaderMinter.sol";
import {ERC20Strategy} from "./interfaces/Strategy.sol";

interface IUniswap {
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}



interface ICurveFactory {
    event BasePoolAdded(address base_pool, address implementat);
    event MetaPoolDeployed(
        address coin,
        address base_pool,
        uint256 A,
        uint256 fee,
        address deployer
    );

    function find_pool_for_coins(address _from, address _to)
    external
    view
    returns (address);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address);

    function get_n_coins(address _pool)
    external
    view
    returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
    external
    view
    returns (address[8] memory);

    function get_decimals(address _pool)
    external
    view
    returns (uint256[2] memory);

    function get_underlying_decimals(address _pool)
    external
    view
    returns (uint256[8] memory);

    function get_rates(address _pool) external view returns (uint256[2] memory);

    function get_balances(address _pool)
    external
    view
    returns (uint256[2] memory);

    function get_underlying_balances(address _pool)
    external
    view
    returns (uint256[8] memory);

    function get_A(address _pool) external view returns (uint256);

    function get_fees(address _pool) external view returns (uint256, uint256);

    function get_admin_balances(address _pool)
    external
    view
    returns (uint256[2] memory);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    )
    external
    view
    returns (
        int128,
        int128,
        bool
    );

    function add_base_pool(
        address _base_pool,
        address _metapool_implementation,
        address _fee_receiver
    ) external;

    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external returns (address);

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function set_fee_receiver(address _base_pool, address _fee_receiver)
    external;

    function convert_fees() external returns (bool);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function pool_list(uint256 arg0) external view returns (address);

    function pool_count() external view returns (uint256);

    function base_pool_list(uint256 arg0) external view returns (address);

    function base_pool_count() external view returns (uint256);

    function fee_receiver(address arg0) external view returns (address);
}
interface ICurve {
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
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IxVader is IERC20 {
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

abstract contract VaderGateway is Auth, IVaderMinter {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    IVaderMinter public immutable VADERMINTER;

    ERC20 public immutable VADER;
    ERC20 public immutable USDV;

    constructor(
        address VADERMINTER_,
        address GOVERNANCE_,
        address VADER_,
        address USDV_
    ) Auth(GOVERNANCE_, Authority(address(0)))
    {
        VADERMINTER = IVaderMinter(VADERMINTER_);
        VADER = ERC20(VADER_);
        USDV = ERC20(USDV_);

        //set approvals
        VADER.safeApprove(VADERMINTER_, type(uint256).max);
        USDV.safeApprove(VADERMINTER_, type(uint256).max);
    }


    function lbt() external view returns (address) {
        return VADERMINTER.lbt();
    }

    // The 24 hour limits on USDV mints that are available for public minting and burning as well as the fee.
    function dailyLimits() external view returns (Limits memory) {
        return VADERMINTER.dailyLimits();
    }

    // The current cycle end timestamp
    function cycleTimestamp() external view returns (uint) {
        return VADERMINTER.cycleTimestamp();
    }

    // The current cycle cumulative mints
    function cycleMints() external view returns (uint) {
        return VADERMINTER.cycleMints();
    }

    // The current cycle cumulative burns
    function cycleBurns() external view returns (uint){
        return VADERMINTER.cycleBurns();
    }

    function partnerLimits(address partner) external view returns (Limits memory){
        return VADERMINTER.partnerLimits(partner);
    }

    // USDV Contract for Mint / Burn Operations
    function usdv() external view returns (address) {
        return VADERMINTER.usdv();
    }

    function getPublicFee() external view returns (uint256) {
        return VADERMINTER.getPublicFee();
    }

    function mint(uint256 vAmount, uint256 uAmountMinOut)
    external requiresAuth
    returns (uint256 uAmount) {
        VADER.safeTransferFrom(msg.sender, address(this), vAmount);
        uAmount = VADERMINTER.mint(vAmount, uAmountMinOut);
        USDV.safeTransferFrom(address(this), msg.sender, uAmount);
    }

    /*
     * @dev Public burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @param vAmountMinOut Vader minimum amount to get back from the burn.
     * @returns vAmount in Vader, represents the Vader amount received from the burn.
     *
     **/
    function burn(uint256 uAmount, uint256 vAmountMinOut)
    external requiresAuth
    returns (uint256 vAmount) {
        USDV.safeTransferFrom(msg.sender, address(this), uAmount);
        vAmount = VADERMINTER.burn(uAmount, vAmountMinOut);
        VADER.safeTransferFrom(address(this), msg.sender, vAmount);
    }
    /*
     * @dev Partner mint function that receives Vader and mints USDV.
     * @param vAmount Vader amount to burn.
     * @returns uAmount in USDV, represents the USDV amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerMint(uint256 vAmount) external requiresAuth returns (uint256 uAmount) {
        VADER.transferFrom(msg.sender, address(this), vAmount);

        uAmount = VADERMINTER.partnerMint(vAmount);

        USDV.safeTransferFrom(address(this), msg.sender, uAmount);
    }
    /*
     * @dev Partner burn function that receives USDV and mints Vader.
     * @param uAmount USDV amount to burn.
     * @returns vAmount in Vader, represents the Vader amount received from the mint.
     *
     * Requirements:
     * - Can only be called by whitelisted partners.
     **/
    function partnerBurn(uint256 uAmount) external requiresAuth returns (uint256 vAmount) {
        USDV.transferFrom(msg.sender, address(this), uAmount);
        vAmount = VADERMINTER.partnerBurn(uAmount);
        VADER.safeTransferFrom(address(this), msg.sender, vAmount);
    }

}

contract USDVOverPegStrategy is Auth, ERC20("USDVOverPegStrategy", "aUSDVOverPegStrategy", 18), ERC20Strategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 public constant DAI = ERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));  //our flip
    ERC20 public constant USDC = ERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); //our flap
    ERC20 public constant USDT = ERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7)); //our flop
    ERC20 public constant USDV = ERC20(address(0xea3Fb6f331735252E7Bfb0b24b3B761301293DBe));

    ERC20 public immutable WETH;
    ICurve public immutable POOL;
    ICurveFactory public immutable FACTORY;
    IUniswap public immutable UNISWAP;
    IxVader public immutable XVADER;
    IVaderMinter public immutable VADERGATEWAY;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        address POOL_,
        address FACTORY_,
        address XVADER_,
        address VADERGATEWAY_,
        address UNIROUTER_,
        address WETH_
    ) Auth(GOVERNANCE_, Authority(address(0))) { //set authority to something that enables operators for aphra
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10**UNDERLYING_.decimals();

        POOL = ICurve(POOL_);
        FACTORY = ICurveFactory(FACTORY_);
        XVADER = IxVader(XVADER_);

        VADERGATEWAY = IVaderMinter(VADERGATEWAY_); // our partner minter
        UNISWAP = IUniswap(UNIROUTER_);
        WETH = ERC20(WETH_);

        USDV.safeApprove(POOL_, type(uint256).max); //set unlimited approval to the pool for usdv
        DAI.safeApprove(UNIROUTER_, type(uint256).max);
        USDC.safeApprove(UNIROUTER_, type(uint256).max);
        USDT.safeApprove(UNIROUTER_, type(uint256).max);
        WETH.safeApprove(UNIROUTER_, type(uint256).max); //prob not needed
        UNDERLYING.safeApprove(VADERGATEWAY_, type(uint256).max);
    }

    /* //////////////////////////////////////////////////////////////
                             STRATEGY LOGIC
    ///////////////////////////////////////////////////////////// */


    function hit(uint256 vAmount_, int128 exitCoin_, address[] memory pathToVader_) external requiresAuth () {
        unstakeUnderlying(vAmount_);
        uint uAmount = VADERGATEWAY.partnerMint(UNDERLYING.balanceOf(address(this)));
        uint vAmount = swapUSDVToVader(uAmount, exitCoin_, pathToVader_);
        stakeUnderlying(vAmount);
    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external override returns (uint256) { //TODO:: this needs to be authed to the vault
        _mint(msg.sender, amount.fdiv(exchangeRate(), BASE_UNIT));

        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        stakeUnderlying(UNDERLYING.balanceOf(address(this)));
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(exchangeRate(), BASE_UNIT));

        if (UNDERLYING.balanceOf(address(this)) < amount) {
            uint leaveAmount = amount - UNDERLYING.balanceOf(address(this));
            unstakeUnderlying(leaveAmount);
        }
        UNDERLYING.safeTransfer(msg.sender, amount);

        return 0;
    }

    function balanceOfUnderlying(address user) external view override returns (uint256) {
        return balanceOf[user].fmul(exchangeRate(), BASE_UNIT);
    }

    /* //////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    ///////////////////////////////////////////////////////////// */

    ERC20 internal immutable UNDERLYING;

    uint256 internal immutable BASE_UNIT;

    function stakeUnderlying(uint vAmount) internal {
        XVADER.enter(vAmount);
    }
    function unstakeUnderlying(uint vAmount) internal {
        uint shares = (vAmount * XVADER.totalSupply()) / UNDERLYING.balanceOf(address(XVADER));

        XVADER.leave(shares);
    }

    function swapUSDVToVader(uint uAmount_, int128 exitCoin_, address[] memory path_) internal returns (uint vAmount) {
        //get best exit address
        address exitCoinAddr = address(DAI);
        if (exitCoin_ == int128(1)) {
            exitCoinAddr = address(USDC);
        } else if (exitCoin_ == int128(2)) {
            exitCoinAddr = address(USDT);
        }

        POOL.exchange(0, exitCoin_, uAmount_, uint(1));

        address[] memory path;
        if(path_.length == 0) {
            path = new address[](3);
            path[0] = exitCoinAddr;
            path[1] = address(WETH);
            path[2] = address(UNDERLYING); //vader eth pool has the best depth for vader
        } else {
            path = new address[](path_.length +1);
            path[0] = exitCoinAddr;

            for (uint i = 0; i < path_.length; i++) {
                path[i+1] = path_[i];
            }
        }

        uint256 amountIn = ERC20(exitCoinAddr).balanceOf(address(this));
        uint256[] memory amounts = UNISWAP.getAmountsOut(amountIn, path);
        vAmount = amounts[amounts.length - 1];
        UNISWAP.swapExactTokensForTokens(
            amountIn,
            vAmount,
            path,
            address(this),
            block.timestamp
        );

    }

    function exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        uint stakedBalance = (XVADER.balanceOf(address(this)) * UNDERLYING.balanceOf(address(XVADER))) / XVADER.totalSupply();
        unchecked {
            underlyingBalance = UNDERLYING.balanceOf(address(this)) + stakedBalance;
        }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }
}

