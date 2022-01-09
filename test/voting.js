const Voting = artifacts.require("./Voting.sol");
const truffleAssert = require('truffle-assertions');

contract("Voting", accounts => {
    let votingInstance;
    let ownerAddress = accounts[0];
    let address  = accounts[1];

    beforeEach(async () => {
        votingInstance = await Voting.deployed();
    })    

    it("...vote status should be set to RegisteringVoters", async () => {
        const status = await votingInstance.getVotingStatus({from: address });
        assert.equal(status, Voting.WorkflowStatus.RegisteringVoters, "Voting status should be RegisteringVoters");
    });

    it("...start proposal registration phase should not be allowed if no voters regsitered", async () => {
        await truffleAssert.fails(votingInstance.startProposalsRegistration({ from:ownerAddress }));
    });

    it("...voter registration should not be allowed from not owner", async () => {
        await truffleAssert.fails(votingInstance.voterRegistration(accounts[2], { from:address }));
    });

    it("...voter registration for 4 addresses", async () => {
        await votingInstance.voterRegistration(accounts[2], { from:ownerAddress });
        await votingInstance.voterRegistration(accounts[3], { from:ownerAddress });
        await votingInstance.voterRegistration(accounts[4], { from:ownerAddress });
        await votingInstance.voterRegistration(accounts[5], { from:ownerAddress });
        const nbVoters = await votingInstance.getNbVoters();
        assert.equal(4, nbVoters, "There should be 4 Voting addresses registered");
    });

    it("...start proposal registration phase should not be allowed if no owner", async () => {
        await truffleAssert.fails(votingInstance.startProposalsRegistration({ from:address }));
    });

    it("...start proposal registration phase", async () => {
        await votingInstance.startProposalsRegistration({from: ownerAddress });
        const status = await votingInstance.getVotingStatus({from: address });
        assert.equal(status, Voting.WorkflowStatus.ProposalsRegistrationStarted, "Voting status should be ProposalsRegistrationStarted");
    });

    it("...make 3 different proposals from 3 different addresses", async () => {
        await votingInstance.proposalRegistration("Proposal 1", { from:ownerAddress });
        await votingInstance.proposalRegistration("Proposal 2", { from:address });
        await votingInstance.proposalRegistration("Proposal 3", { from:accounts[3] });
        const nbProposal = await votingInstance.getNbProposals();
        assert.equal(3, nbProposal, "There should be 3 proposals");
    });

    it("...stop proposal registration phase should not be allowed if no owner", async () => {
        await truffleAssert.fails(votingInstance.stopProposalsRegistration({ from:address }));
    });

    it("...stop proposal registration phase", async () => {
        await votingInstance.stopProposalsRegistration({from: ownerAddress });
        const status = await votingInstance.getVotingStatus({from: address });
        assert.equal(status, Voting.WorkflowStatus.ProposalsRegistrationEnded, "Voting status should be ProposalsRegistrationEnded");
    });

    it("...start voting phase should not be allowed if no owner", async () => {
        await truffleAssert.fails(votingInstance.startVotingSession({ from:address }));
    });

    it("...start voting phase", async () => {
        await votingInstance.startVotingSession({from: ownerAddress });
        const status = await votingInstance.getVotingStatus({from: address });
        assert.equal(status, Voting.WorkflowStatus.VotingSessionStarted, "Voting status should be VotingSessionStarted");
    });
});