pragma solidity ^0.8.10;

import {ERC20} from "solmate/token/ERC20.sol";

contract AphraToken is Auth, ERC20("Aphra Finance DAO", "APHRA", 18) {

    address public treasury;

    constructor(
        address TREASURY_,
        address AUTHORITY_
    ) Auth(TREASURY_, Authority(AUTHORITY_)) {

    }
}
