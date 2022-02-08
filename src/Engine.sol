// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {Auth, Authority} from "solmate/auth/Auth.sol";
import "../lib/weiroll/contracts/VM.sol";
import "./Registry.sol";

contract Engine is Auth {

    error ExecutionFailed(bytes failedState);
    error InvalidStateUpdate();
    Registry public registry;

    VM public vm;

    modifier onlyGuardian() {
        require(msg.sender == guardian);
        _;
    }

    address public guardian;

    constructor(
        VM _vm,
        address _guardian,
        address _registry,
        address _authority
        ) Auth(_guardian, Authority(_authority)) {
        vm = _vm;
        guardian = _guardian;
        registry = Registry(_registry);
    }

    //make this function upgradeable
    function validateState(bytes memory preState) public returns (bool) {
        return registry.validateState(preState);
    }

    ///can we get a nice merkle proof of the commands verified here?
    //        // is it possible to return from the vm a packet of data that we can prove in a merkle or zksnark

    function execute(bytes32[] calldata commands, bytes[] memory state)
    public
    onlyGuardian
    returns (bytes[] memory)
    {
        PegTarget memory pegTarget = registry.getPegData(registry.stableLookup('usdv'));
        bytes memory pegHealthBefore = abi.encodePacked(IPool(pegTarget.pool).healthFactor()); //setup pre exeuction state for post execution validation
        (bool success, bytes memory data) = address(vm).delegatecall(
            abi.encodeWithSelector(VM.execute.selector, commands, state)
        );
        if (!success) revert ExecutionFailed(data);

        if (!validateState(pegHealthBefore)) revert InvalidStateUpdate();
        //require engine state to be valid to be healthy

        return abi.decode(data, (bytes[]));
    }
}
