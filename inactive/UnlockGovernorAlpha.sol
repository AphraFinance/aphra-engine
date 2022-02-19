pragma solidity ^0.8.11;
import {veAPHRA} from "./veAPHRA.sol";
pragma experimental ABIEncoderV2;

contract UnlockGovernorAlpha {
    /// @notice The name of this contract
    string public constant name = "Aphra Badge Governor Alpha";

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public pure returns (uint) { return 12_500_000e18; } // 12,500,000 = 12.5% of Aphra Comp

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) { return 2500e18; } // 2500 = 1% of Comp

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 1; } // 1 can only unlock veAphra

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

    /// @notice The address of an aphra ve lock token
    veAPHRA public ve;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        uint proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (uint => Receipt) receipts;
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
        Defeated,
        Succeeded,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (uint => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 badgeId,uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, uint proposalBadgeId, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(uint badgeId, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);
    event Activation(uint veSupply);

    constructor(address veAPHRA_) {
        ve = veAPHRA(veAPHRA_);
    }

    function propose(uint badgeId, string memory description) public returns (uint) {
        require(ve.balanceOfNFTAt(badgeId, (block.number - 1)) > proposalThreshold(), "UnlockGovernorAlpha::propose: proposer votes below proposal threshold");

        uint latestProposalId = latestProposalIds[badgeId];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "UnlockGovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "UnlockGovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = block.number + votingDelay();
        uint endBlock = startBlock + votingPeriod();


        Proposal storage newProposal = proposals[proposalCount++];
        newProposal.proposer = badgeId;
        newProposal.eta = 0;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, badgeId, startBlock, endBlock, description);
        return newProposal.id;
    }

    function executeUnlock(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Succeeded, "UnlockGovernorAlpha::execute: proposal can only be executed if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        ve.unlock();
        emit ProposalExecuted(proposalId);
        emit Activation(ve.totalSupply());
    }


    function getReceipt(uint proposalId, uint badgeId) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[badgeId];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "UnlockGovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        }else {
            return ProposalState.Expired;
        }
    }

    function castVote(uint badgeId, uint proposalId, bool support) public {
        require(msg.sender == ve.ownerOf(badgeId));
        return _castVote(badgeId, proposalId, support);
    }

    function castVoteBySig(uint badgeId, uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH,badgeId, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory == ve.ownerOf(badgeId), "UnlockGovernorAlpha::castVoteBySig: invalid signature");

        return _castVote(badgeId, proposalId, support);
    }

    function _castVote(uint badgeId, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "UnlockGovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[badgeId];
        require(receipt.hasVoted == false, "UnlockGovernorAlpha::_castVote: voter already voted");
        uint votes = ve.balanceOfNFTAt(badgeId, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(badgeId, proposalId, support, votes);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
