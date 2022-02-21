// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import {veAPHRA} from "../veAPHRA.sol";
import {Timelock} from "./Timelock.sol";

contract veGovernor {
    /// @notice The name of this contract
    string public constant name = "Aphra veGovernor";

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public pure returns (uint) {return 12_500_000e18;} // 12.5M = 12.5% of Aphra

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) {return 2500e18;} // 2500 = 0.000025% of Aphra

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) {return 10;} // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) {return 1;} // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) {return 40320;} // ~1 days in blocks (assuming 15s blocks)

    /// @notice The address of the APHRA Protocol Timelock
    Timelock public timelock;

    /// @notice The address of the veAPHRA token
    veAPHRA public ve;

    /// @notice The address of the veGovernor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        uint badgeId;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping(uint => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping(uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(uint => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, uint badgeId, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(uint badgeId, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(Timelock timelock_, veAPHRA ve_, address guardian_) {
        timelock = timelock_;
        ve = ve_;
        guardian = guardian_;
    }
    function propose(uint badgeId_, address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(ve.balanceOfNFTAt(badgeId_, (block.number - 1)) > proposalThreshold(), "veGovernor::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "veGovernor::propose: proposal function information arity mismatch");
        require(targets.length != 0, "veGovernor::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "veGovernor::propose: too many actions");

        uint latestProposalId = latestProposalIds[badgeId_];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "veGovernor::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "veGovernor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = (block.number + votingDelay());
        uint endBlock = (startBlock + votingPeriod());

        Proposal storage newProposal = proposals[proposalCount++];


        newProposal.id = proposalCount;
        newProposal.badgeId = badgeId_;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.badgeId] = newProposal.id;

        emit ProposalCreated(newProposal.id, badgeId_, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint proposalId_) public {
        require(state(proposalId_) == ProposalState.Succeeded, "veGovernor::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId_];
        uint eta = (block.timestamp + timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId_, eta);
    }

    function _queueOrRevert(address target_, uint value_, string memory signature_, bytes memory data_, uint eta_) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target_, value_, signature_, data_, eta_))), "veGovernor::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target_, value_, signature_, data_, eta_);
    }

    function execute(uint proposalId_) public payable {
        require(state(proposalId_) == ProposalState.Queued, "veGovernor::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId_];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value:proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId_);
    }

    function cancel(uint proposalId_) public {
        ProposalState currentState = state(proposalId_);
        require(currentState != ProposalState.Executed, "veGovernor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId_];
        require(msg.sender == guardian || ve.balanceOfNFTAt(proposal.badgeId, (block.number - 1)) < proposalThreshold(), "veGovernor::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId_);
    }

    function getActions(uint proposalId_) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId_];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId_, uint badgeId_) public view returns (Receipt memory) {
        return proposals[proposalId_].receipts[badgeId_];
    }

    function state(uint proposalId_) public view returns (ProposalState) {
        require(proposalCount >= proposalId_ && proposalId_ > 0, "veGovernor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId_];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= (proposal.eta + timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint badgeId_, uint proposalId_, bool support_) public {
        require(msg.sender == ve.ownerOf(badgeId_));
        return _castVote(badgeId_, proposalId_, support_);
    }

    function castVoteBySig(uint badgeId_, uint proposalId_, bool support_, uint8 v_, bytes32 r_, bytes32 s_) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, badgeId_, proposalId_, support_));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v_, r_, s_);

        require(signatory == ve.ownerOf(badgeId_), "veGovernor::castVoteBySig: invalid signature");

        return _castVote(badgeId_, proposalId_, support_);
    }

    function _castVote(uint badgeId_, uint proposalId_, bool support_) internal {
        require(state(proposalId_) == ProposalState.Active, "veGovernor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId_];
        Receipt storage receipt = proposal.receipts[badgeId_];
        require(receipt.hasVoted == false, "veGovernor::_castVote: badgeId already voted");
        uint votes = ve.balanceOfNFTAt(badgeId_, proposal.startBlock);

        if (support_) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support_;
        receipt.votes = votes;

        emit VoteCast(badgeId_, proposalId_, support_, votes);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "veGovernor::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "veGovernor::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin_, uint eta_) public {
        require(msg.sender == guardian, "veGovernor::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin_), eta_);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin_, uint eta_) public {
        require(msg.sender == guardian, "veGovernor::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin_), eta_);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}
