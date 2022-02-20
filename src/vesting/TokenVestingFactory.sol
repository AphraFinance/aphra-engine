// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
import {Auth, Authority, ERC20, TokenVesting} from "./TokenVesting.sol";
import {veAPHRA} from "../veAPHRA.sol";
/**
 * @title TokenVestingFactory
 * @dev A factory to deploy instances of TokenVesting for RSR, nothing more.
 */
contract TokenVestingFactory is Auth  {

    event TokenVestingDeployed(address indexed location, address indexed recipient);
    veAPHRA public _ve;
    mapping (address => address) public vestingContracts;
    constructor(
        address GOVERNANCE_,
        address VE_APHRA_ADDR_
    ) Auth (GOVERNANCE_, Authority(address(0))) {
        _ve = veAPHRA(VE_APHRA_ADDR_);
    }

    function deployVestingContract(address recipient, uint256 vestForThisManySeconds) requiresAuth external returns (address) {

        TokenVesting vesting = new TokenVesting(
            recipient,
            block.timestamp,
            block.timestamp + vestForThisManySeconds
        );

        vestingContracts[recipient] = address(vesting);

        emit TokenVestingDeployed(address(vesting), recipient);
        return address(vesting);
    }

    function clawbackVesting(ERC20 token, TokenVesting vesting) requiresAuth external {
        vesting.reclaimUnderlying(token, owner);
    }

    //should we update ve before unlock switch happens
    function setVe(address newVEAPHRA_) requiresAuth external {
        require(!_ve.isUnlocked(), "veAPHRA has already been unlocked, nothing can be done");
        _ve = veAPHRA(newVEAPHRA_);
    }

    function getVe() external view returns (address) {
        return address(_ve);
    }

    function getVestingContract(address benefactor) external view returns (address) {
        return vestingContracts[benefactor];
    }
}
