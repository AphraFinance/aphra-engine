// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library PoolLib {
    function healthFactor() internal returns (uint32) {
        return 1;
    }
}
struct PegTarget {
    address pool;
    uint32 healthFactor; // std deviation from the mid point
    uint32[2] activeRange; //left bps below peg, right, bps above peg
}
interface IPool {
    function healthFactor() external returns (uint32);
}
interface IRegistry {
    function isValidCommand(address contractAddress, bytes4 selector) external view returns (bool valid);
    function getPrimePeg() external returns (address);
    function getPegData(address stable) external returns (PegTarget memory);
    function getPegData(address stable, uint32 index) external returns (PegTarget memory);
}


interface Peg {
    function poolType() external returns (uint8);
    function pool() external returns (address);
    function healthFactor() external returns (bytes memory);
    function getUnderlyingAssets() external returns (uint256[] memory);
}

contract Registry {

    mapping(address => mapping(address => PegTarget)) public targets;

    mapping(address => address) public primePools;

    mapping(string => address) public stableLookup;

    mapping(address => mapping(bytes4 => bool)) public isActiveCommand;

    mapping(bytes32 => bool) public byteCodeAllowList;

    address governance;

    address futureGovernance;

    constructor(address multiSig) {
        governance = multiSig;
    }

    function getPrimePeg(address stable) public view returns (address) {
        return primePools[stable];
    }

    function getPegData(address stable) public view returns (PegTarget memory data) {
        address pool = getPrimePeg(stable);
        data = targets[stable][pool];
    }

    function setStableLookup(string calldata coin, address addr) external onlyGovernance {
        stableLookup[coin] = addr;
    }

    function setTarget(address asset,address pool, uint8 poolType, uint32 healthTarget, uint32[2] memory bpsRange) external onlyGovernance {
        targets[asset][pool] = PegTarget(pool, healthTarget, bpsRange);
    }

    //make this function upgradeable
    function validateState(bytes memory preState) public returns (bool healthy) {
        //getPegs to start is just usdv
        PegTarget memory pegTarget = getPegData(stableLookup["usdv"]);
        return (pegTarget.healthFactor >= IPool(pegTarget.pool).healthFactor());
    }

    function transferGovernance(address governance_) external onlyGovernance {
        require(governance_ != address (0), "can't be nobody steering the ship");
        futureGovernance = governance_;
    }

    function acceptGovernance() external {
        require(msg.sender == futureGovernance, "must be futureGovernance to accept");
        governance = futureGovernance;
        futureGovernance = address(0);
    }

    function isValidCommand(address contractAddress, bytes4 selector)
    external
    view
    returns (bool valid) {
        bytes32 codeHash;
        assembly {codeHash := extcodehash(contractAddress)}

        valid = (byteCodeAllowList[codeHash] && isActiveCommand[contractAddress][selector]);
    }

    function registerNewCommands(address[] calldata contractsToEnable, bytes4[] calldata selectorsToEnable)
    public
    onlyGovernance {
        require(contractsToEnable.length == selectorsToEnable.length, "invalid length mismatch");
        for (uint i = 0; i < contractsToEnable.length; i++) {
            _registerNewContract(contractsToEnable[i], selectorsToEnable[i]);
        }
    }

    modifier onlyGovernance() {
        require(address(msg.sender) == governance);
        _;
    }
    function _registerNewContract(address externalContract, bytes4 selector) internal onlyGovernance {
        bytes32 codeHash;
        assembly {codeHash := extcodehash(externalContract)}

        require(!isActiveCommand[externalContract][selector], "Command already added");

        byteCodeAllowList[codeHash] = true; //set into its own function maybe for 2 step activation, code and then contract/selector
        isActiveCommand[externalContract][selector] = true;
    }
}
