<template>
  <div class="hello">
    <h1>{{ msg }}</h1>
    <div class="p-4" v-show="this.votingStatus == 0">
        <h2>Vote Phase: User Registration</h2>
        <form @submit.prevent="registerVoter">
            <InputText v-model="voterAddress" type="text"/>
            <Button label="Enregistrer" class="p-button-sm p-ml-4"  @click="registerVoter()"/>
        </form>        
        <Button label="Finish" @click="nextPhase()" />
        <div> {{ msgStatus }} </div>
    </div>
    <div class="p-4" v-show="this.votingStatus == 1">
        <h2>Vote Phase: Proposal Registration Phase</h2>
        <form >
            <InputText v-model="voterProposal" type="text"/>
            <Button label="Enregistrer" class="p-button-sm p-ml-4"  @click="registerProposal()"/>
        </form>
        <Button label="Finish" @click="nextPhase()" />
        <div>
        <Listbox :options="proposals" optionLabel="name" style="width:15rem" />
        </div>
    </div>
    <div class="p-4" v-show="this.votingStatus == 2">
        <h2>Vote Phase: Proposal Registration Phase Finished</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 3">
        <h2>Vote Phase: Vote Registration Phase</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 4">
        <h2>Vote Phase: Vote Registration Phase Finished</h2>
    </div>                
    <div class="p-4" v-show="this.votingStatus == 5">
        <h2>Vote Phase: Vote Results</h2>
    </div>
  </div>
</template>

<script>
// importing common function
import mixin from '../libs/mixinViews';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Listbox from 'primevue/listbox';

export default {
  name: 'VoteStatus',
  mixins: [mixin],
  components: {
      InputText,
      Listbox,
      Button
  },
  data () {
    return {
      msg: 'Welcome to Your Vue.js Vote dApp',
      votingStatus: 1000,
      voterAddress: '',
      voterProposal: '',
      msgStatus: '',
      proposals: [],
      tmoConn: null // contain the intervalID given by setInterval
    }
  },

  methods: {
    waitContractInit() {
      if (this.blockchainIsConnected()) {
        clearInterval(this.tmoConn);
        window.bc.contract().getVotingStatus((err, status) => {
          this.updateVotingStatus(status);
        });

        let VoterRegistered = window.bc.contract().VoterRegistered();
        VoterRegistered.watch((err, result) => {
          if (err) {
            console.log('could not get event VoterRegistered()')
          } else {
            console.log("voterRegistered event received");
            console.log(result.args);
          }
        });
        window.bc.contract().WorkflowStatusChange().watch((err, result) => {
          if (err) {
            console.log('could not get event WorkflowStatusChange()')
          } else {
            console.log("WorkflowStatusChange event received");
            console.log(result.args);
            this.updateVotingStatus(result.args.newStatus);
          }
        });
        window.bc.contract().ProposalRegistered().watch((err, result) => {
          if (err) {
            console.log('could not get event ProposalRegistered()')
          } else {
            console.log("ProposalRegistered event received");
            console.log(result.args);
            this.addProposal(result.args.proposalId);
          }
        });
      }
    },
    updateVotingStatus(status) {
      this.votingStatus = status;
      if (this.votingStatus == 1) {
        this.initProposalList();
      }
    },
    nextPhase() {
      if (this.blockchainIsConnected()) {
        window.bc.getMainAccount()
        .then(account => {
          window.bc.contract().getVotingStatus((err, status) => {
            if (status == 0) {
              window.bc.contract().startProposalsRegistration({ from: account }, (error, res) => {
                if (error) reject(error);
              });
            }
          });
        });
      }
    },
    registerVoter() {
        if (this.blockchainIsConnected()) {
          //window.bc.contract().voterRegistration(this.voterAddress);

          window.bc.getMainAccount()
          .then(account => {
              window.bc.contract().voterRegistration(this.voterAddress, { from: account }, (error, txHash) => {
                  if (error) {
                    this.msgStatus = "Error. Check console logs";
                    console.error(error);
                  }
                  else
                    this.msgStatus = "User Registration Requested";
                    this.voterAddress = "";
                  //resolve(res);
              });
          })
          .catch(error => reject(error));

        }    
    },
    registerProposal() {
        if (this.blockchainIsConnected()) {
          window.bc.getMainAccount()
          .then(account => {
              window.bc.contract().proposalRegistration(this.voterProposal, { from: account }, (error, txHash) => {
                  if (error) {
                    this.msgStatus = "Error. Check console logs";
                    console.error(error);
                  }
                  else
                    this.msgStatus = "Proposal Registration Requested";
                    this.voterProposal = "";
              });
          })
          .catch(error => reject(error));
        }    
    },
    initProposalList() {
      if (this.blockchainIsConnected()) {

        this.proposals.splice(0, this.proposals.length);
        //this.proposals = [];

        window.bc.contract().getNbProposals((err, nbProposal) => {
          for (let i=1;i<=nbProposal;i++) {
            window.bc.contract().getProposal(i, (err, strProposal) => {
              console.log(strProposal);
              this.proposals.push({name: strProposal, id: i});
            });
          }
        });          
      }
    },
    addProposal(proposalId) {
      console.log(this.proposals);

      proposalId = parseInt(proposalId.toString(), 10);

      for (let j=0;j<this.proposals.length;j++) {
        if (this.proposals[j].id == proposalId)
          return;
      }

      if (this.blockchainIsConnected()) {
        window.bc.contract().getProposal(proposalId, (err, strProposal) => {
          var found = false;
          console.log(strProposal + "id=" + proposalId);
          for (let j=0;j<this.proposals.length;j++) {
            if (this.proposals[j].id == proposalId) {
              found = true;
              break;
            }
          }
          if (!found)
            this.proposals.push({name: strProposal, id: proposalId});
        });
      }
    },
  },
  created() {
      // it tries to get the user list from the blockchian once
      // the connection is established
      this.tmoConn = setInterval(() => {
        this.waitContractInit();
      }, 1000);
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h1, h2 {
  font-weight: normal;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>
