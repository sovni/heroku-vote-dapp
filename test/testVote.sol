// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {

  function convertStatus(Voting.WorkflowStatus wStatus) private pure returns (uint) {
    uint result;
 
    if (wStatus == Voting.WorkflowStatus.RegisteringVoters)
      result = 1;
    else if (wStatus == Voting.WorkflowStatus.ProposalsRegistrationStarted)
      result = 2;      
    else if (wStatus == Voting.WorkflowStatus.ProposalsRegistrationEnded)
      result = 3;
    else if (wStatus == Voting.WorkflowStatus.VotingSessionStarted)
      result = 4;
    else if (wStatus == Voting.WorkflowStatus.VotingSessionEnded)
      result = 5;
    else if (wStatus == Voting.WorkflowStatus.VotesTallied)
      result = 6;
    else
      result = 0;
    return result;
  }

  function testContractCreation() public {
    Voting vote = Voting(DeployedAddresses.Voting());
    uint expected = convertStatus(Voting.WorkflowStatus.RegisteringVoters);

    Assert.equal(convertStatus(vote.getVotingStatus()), expected, "Voting Status should be set to RegisteringVoters");

  }

  // not possible to est onlyOwner function with solidity test
  /*function testStartProposal() public {
    Voting vote = Voting(DeployedAddresses.Voting());
    vote.startProposalsRegistration({from: accounts[0]});
    uint expected = convertStatus(Voting.WorkflowStatus.ProposalsRegistrationStarted);

    Assert.equal(convertStatus(vote.getVotingStatus()), expected, "Voting Status should be set to ProposalsRegistrationStarted");
  }*/
}