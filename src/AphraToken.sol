pragma solidity ^0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

contract AphraToken is Auth, ERC20("Aphra Finance DAO", "APHRA", 18) {

    constructor(
        address GOVERNANCE_,
        address AUTHORITY_
    ) Auth(GOVERNANCE_, Authority(AUTHORITY_)) {
        _mint(msg.sender, 0);
    }

    function mint(address account, uint amount) requiresAuth external returns (bool) { //minter is allowed to call
        _mint(account, amount);
        return true;
    }
}
