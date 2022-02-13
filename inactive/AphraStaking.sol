pragma solidity ^0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {veAPHRA} from "./veAphra.sol";

contract AphraStaking is Auth {

    using SafeTransferLib for ERC20;

    error BadWithdraw();
    error NoDevLPWithdraw();
    error NoEarlyDevWithdraw();

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    uint256 constant OFFSET = uint256(1e12);
    uint256 constant LOCK_DURATION = uint256(1e12);// TODO: Set
    // Info of each pool.
    struct PoolInfo {
        ERC20 depositAsset;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool.
        uint256 lastRewardBlock;  // Last block number that APHRA distribution occurs.
        uint256 accAphraPerShare; // Accumulated Aphra per share, times OFFSET. See below.
    }

    ERC20 public immutable aphraToken;
    veAPHRA public immutable voteEscrow;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public aphraPerBlock;
    uint256 public totalAllocPoint = 0;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (address => uint256) public activeBadge;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DevWithdraw(address token, uint amount);

    constructor(
        address GOVERNANCE_,
        address AUTHORITY_,
        address VOTE_ESCROW_,
        address APHRA_,
        uint256 APHRA_PER_BLOCK_,
        uint256 STARTBLOCK_,
        uint256 ENDBLOCK_
    ) Auth(GOVERNANCE_, Authority(AUTHORITY_)) public {
        aphraToken = ERC20(APHRA_);
        aphraPerBlock = APHRA_PER_BLOCK_;
        endBlock = ENDBLOCK_;
        startBlock = STARTBLOCK_;
        voteEscrow = veAPHRA(address(VOTE_ESCROW_));
        aphraToken.safeApprove(VOTE_ESCROW_, type(uint256).max);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new asset to the pool. Can only be called by the owner.
    // XXX DO NOT add the same asset token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, ERC20 _depositAsset) public requiresAuth {
        massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            depositAsset: _depositAsset,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accAphraPerShare: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint) public requiresAuth {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint _endBlock = endBlock; // gas savings
        if (_from >= _endBlock) {
            return 0;
        } else {
            return _to >= _endBlock ? _endBlock - _from : _to - _from;
        }
    }

    function pendingAPHRA(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAphraPerShare = pool.accAphraPerShare;
        uint256 lpSupply = pool.depositAsset.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 aphraReward = (multiplier * aphraPerBlock * pool.allocPoint) / totalAllocPoint;

            accAphraPerShare = accAphraPerShare + ((aphraReward * OFFSET) / lpSupply);
        }
        return ((user.amount * accAphraPerShare) / OFFSET) - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 depositAssetSupply = pool.depositAsset.balanceOf(address(this));
        if (depositAssetSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 aphraReward = (multiplier * aphraPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accAphraPerShare = pool.accAphraPerShare + ((aphraReward * OFFSET) / depositAssetSupply);
        pool.lastRewardBlock = block.number;
    }

    // Deposit Asset tokens to AphraStaking contract for APHRA allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accAphraPerShare) / OFFSET) - user.rewardDebt;
            if(pending > 0) {
                _claimAndLockVe(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.depositAsset.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = (user.amount * pool.accAphraPerShare) / OFFSET;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from aphra staking contract.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (_amount > user.amount) revert BadWithdraw();
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accAphraPerShare) / OFFSET) - user.rewardDebt;
        if(pending > 0) {
            _claimAndLockVe(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.depositAsset.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accAphraPerShare) / OFFSET;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.depositAsset.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe if transfer function, just in case if rounding error causes pool to not have enough APHRAs.
    function _claimAndLockVe(address _to, uint256 _amount) internal {

        uint256 depositAmount = _amount;
        //
        if (_amount > aphraToken.balanceOf(address(this))) {
            depositAmount = aphraToken.balanceOf(address(this));
        }

        //check to see if a the receiving user has an lock.
        if (activeBadge[_to] != uint(0) && voteEscrow.ownerOf(activeBadge[_to]) == _to) {
            voteEscrow.deposit_for(activeBadge[_to], depositAmount);
        } else {
            activeBadge[_to] = voteEscrow.create_lock_for(depositAmount, LOCK_DURATION, _to);
        }
    }

    // Withdraws remaining APHRA balance in contract. Can only be called after endblock
    function removeAphraBalance(uint amount) external requiresAuth {
        if(endBlock > block.number) revert NoEarlyDevWithdraw();
        aphraToken.safeTransfer(owner, amount);
        emit DevWithdraw(address(aphraToken), amount);
    }

    // retrieve other tokens erroneously sent in to this address
    // Cannot withdraw LP tokens!!
    function emergencyTokenRetrieve(address token) external requiresAuth {
        uint i;
        for (i = 0; i < poolInfo.length; i++) {
            if (token == address(poolInfo[i].depositAsset)) revert NoDevLPWithdraw();
        }

        uint balance = ERC20(token).balanceOf(address(this));

        ERC20(token).safeTransfer(
            owner,
            balance
        );

        emit DevWithdraw(address(token), balance);
    }
}
