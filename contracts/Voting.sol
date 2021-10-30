// voting.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "./Ownable.sol";


contract Voting is Ownable{
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    uint private proposalIndex;
    uint private winningProposalId;
    uint private voteCountMax;
    uint private nbVoters;

    WorkflowStatus private votingStatus;
    mapping(uint => Proposal) private proposals;
    mapping(address => Voter) private voters;

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);    


   constructor() public {
        votingStatus = WorkflowStatus.RegisteringVoters;
        proposalIndex = 1;
   }

    function startProposalsRegistration() public onlyOwner {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "Allowed only after voter registration phase");
        require(nbVoters > 0, "No voters registered");

        votingStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }

    function stopProposalsRegistration() public onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, "Allowed only during proposal registration phase");
        require(proposalIndex > 1, "No proposal submitted yet");

        votingStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }

    function startVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationEnded, "Allowed only after proposal registration phase");

        votingStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }

    function stopVotingSession() public onlyOwner {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "Allowed only during voting phase");
        require(voteCountMax > 0, "No vote submitted yet");

        votingStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();

        votingStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        emit VotesTallied();        
    }

    function voterRegistration(address _address) public onlyOwner {
        require(!voters[_address].isRegistered, "This voter is already registered !");
        require(votingStatus == WorkflowStatus.RegisteringVoters, "Registering phase finished");

        voters[_address].isRegistered = true;
        voters[_address].hasVoted = false;
        nbVoters++;
        emit VoterRegistered(_address);
    }

    function proposalRegistration(string calldata description) public {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, "Not allowed outside of the proposal registering phase");

		proposals[proposalIndex].description = description;
        emit ProposalRegistered(proposalIndex);
        proposalIndex++;
    }

    function voting(uint proposalId) public {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "Not allowed outside of the voting phase");
        require(voters[msg.sender].isRegistered, "Voter not registered");
        require(!voters[msg.sender].hasVoted, "Voter already voted");
        require(proposalId > 0 && proposalId < proposalIndex, "Proposition not found");

        voters[msg.sender].hasVoted = true; 
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount++;
        if (proposals[proposalId].voteCount > voteCountMax) {
            voteCountMax = proposals[proposalId].voteCount;
            winningProposalId = proposalId;
        }
        emit Voted(msg.sender, proposalId);
    } 

    function getWinningProposal() public view returns (string memory) {
        require(votingStatus == WorkflowStatus.VotesTallied, "Voting session not finished yet");
        require(winningProposalId > 0, "No vote done - no result");
        return proposals[winningProposalId].description;
    }

    function getWinnngVotes() public view returns (uint) {
        require(votingStatus == WorkflowStatus.VotesTallied, "Voting session not finished yet");
        require(winningProposalId > 0, "No vote done - no result");
        return proposals[winningProposalId].voteCount;
    }
    
    function getVotingStatus() public view returns (WorkflowStatus) {
        return votingStatus;
    }
}