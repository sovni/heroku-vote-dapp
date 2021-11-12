<template>
  <div class="p-flex-column p-m-2">

    <div class="p-mt-2">
      <h1>{{ msg }}</h1>
    </div>
    <div class="p-mt-2">
      <Card>
        <template #title>
          Vote current status
        </template>
        <template #content>    
          <Timeline :value="statusList" layout="horizontal">
            <template #marker="slotProps">
              <span class="custom-marker p-shadow-2" :style="{backgroundColor: slotProps.item.color}">
                <i :class="slotProps.item.icon"></i>
              </span>
            </template>
            <template #content="slotProps">
              {{slotProps.item.status}}
            </template>
          </Timeline>
        </template>
      </Card>        
    </div>
    <div v-show="this.votingStatus == 0">
      <div class="p-d-inline-flex p-flex-row p-mt-2">
        <Card style="width:600px;height:400px;" class="p-d-flex">
          <template #title>
          Register new Voter
          </template>
          <template #content>    
            <form @submit.prevent="registerVoter">
                <InputText v-model="voterAddress" style="width:400px" type="text"/>
                <Button label="Enregistrer" class="p-button-sm p-ml-2"  @click="registerVoter()"/>
            </form>        
          </template>
          <template #footer>
            <Button label="Start Proposal Phase" @click="nextPhase()" class="p-mt-2" />
          </template>
        </Card>
        <Card style="width:600px;height:400px;" class="p-ml-2">
          <template #title>
          Number of voters
          </template>
          <template #content>
            {{ nbVoters }}
          </template>
        </Card>
      </div>
    </div>

    <div v-show="this.votingStatus == 1">
      <div class="p-d-inline-flex p-flex-row p-mt-2">
        <Card style="width:600px;height:400px;">
          <template #title>
            Register new Proposal
          </template>
          <template #content>    
            <form >
              <InputText v-model="voterProposal" style="width:400px" type="text" class="m-t-2"/>
              <Button label="Enregistrer" class="p-button-sm p-ml-2"  @click="registerProposal()"/>
            </form>
          </template>
          <template #footer>
            <Button label="Finish Proposal Phase" @click="nextPhase()" class="p-mt-2" />
          </template>
        </Card>
        <Card style="width:600px;height:400px;" class="p-ml-2">
          <template #title>
            Proposal List
          </template>
          <template #content>
            <Listbox :options="proposals" optionLabel="name" listStyle="max-height:300px" style="width:550px;height:300px;" />
          </template>
        </Card>
      </div>   
    </div>
    <div v-show="this.votingStatus == 2">
      <Card style="width:600px;height:400px;" class="p-mt-2">
         <template #title>
            Proposal Registration Phase Finished
          </template>
          <template #content>  
            Please wait before voting phase starts
          </template>
          <template #footer>
              <Button label="Start Vote" @click="nextPhase()"  class="p-mt-2"/>
          </template>
      </Card>
    </div>

    <div v-show="this.votingStatus == 3">
      <Card style="width:600px;height:800px;" class="p-mt-2">
         <template #title>
            Vote
          </template>
          <template #content>  
            <Listbox v-model="selectedVote"  :options="proposals" listStyle="max-height:500px" optionLabel="name" style="width:550px;height:500px" />
            <Button label="Confirm Vote" @click="confirmVote()" class="p-mt-2"/>
          </template>
          <template #footer>
            <Button label="Finish Vote" @click="nextPhase()" />
          </template>
      </Card>
    </div>

    <div v-show="this.votingStatus == 4">
      <h2>Vote Phase: Vote Registration Phase Finished</h2>
    </div>

    <div v-show="this.votingStatus == 5">
      <Card class="p-mt-2">
        <template #title>
        Results
        </template>
        <template #content>  
          Winning Proposal : {{winningProposal}}
          <br/>Number of votes : {{nbWinningVotes}}
        </template>
      </Card>
    </div>
    <div> {{ msgStatus }} </div>

  </div>
</template>

<script>
// importing common function
import mixin from '../libs/mixinViews';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Listbox from 'primevue/listbox';
import Card from 'primevue/card';
import Timeline from 'primevue/timeline';

export default {
  name: 'VoteStatus',
  mixins: [mixin],
  components: {
      InputText,
      Listbox,
      Card,
      Timeline,
      Button
  },
  data () {
    return {
      msg: 'Welcome to Your Vue.js Vote dApp',
      votingStatus: 1000,
      voterAddress: '',
      voterProposal: '',
      nbVoters : 0,
      msgStatus: '',
      proposals: [],
      selectedVote: null,
      winningProposal: '',
      nbWinningVotes : 0,
      statusList : [
                {status: 'User Registration', icon: 'pi pi-circle-off'},
                {status: 'Proposals Registration', icon: 'pi pi-circle-off'},
                {status: 'Waiting for vote...', icon: 'pi pi-circle-off'},
                {status: 'Voting', icon: 'pi pi-circle-off'},
                {status: 'Calculating Result', icon: 'pi pi-circle-off'},
                {status: 'Results', icon: 'pi pi-circle-off'},
      ],
      tmoConn: null // contain the intervalID given by setInterval
    }
  },

  methods: {
    waitContractInit() {
      if (this.blockchainIsConnected()) {
        clearInterval(this.tmoConn);
        window.bc.contract().getVotingStatus((err, status) => {
          this.updateVotingStatus(status);
          this.statusList[status].icon = 'pi pi-circle-on';
          if (this.votingStatus == 0) {
            this.updateNumberVoters();
          }
          else if (this.votingStatus == 1) {
            this.initProposalList();
          }
          else if (this.votingStatus == 5) {
            this.updateWinningVote();
          }
        });

        let VoterRegistered = window.bc.contract().VoterRegistered();
        VoterRegistered.watch((err, result) => {
          if (err) {
            console.log('could not get event VoterRegistered()')
          } else {
            console.log("voterRegistered event received");
            console.log(result.args);
            this.updateNumberVoters();
          }
        });
        window.bc.contract().WorkflowStatusChange().watch((err, result) => {
          if (err) {
            console.log('could not get event WorkflowStatusChange()')
          } else {
            console.log("WorkflowStatusChange event received");
            console.log(result.args);
            this.updateVotingStatus(result.args.newStatus);
            this.statusList[result.args.newStatus].icon = 'pi pi-circle-on';
            this.statusList[result.args.previousStatus].icon = 'pi pi-circle-off';
            if (this.votingStatus == 5)
              this.updateWinningVote();
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
    updateWinningVote() {
      window.bc.contract().getWinningProposal((err, prop) => {
        this.winningProposal = prop;
      });
      window.bc.contract().getWinningVotes((err, nb) => {
        this.nbWinningVotes = nb;
      });
    },
    updateVotingStatus(status) {
      this.votingStatus = status;
      if (this.votingStatus == 1 || this.votingStatus == 3) {
        this.initProposalList();
      }
    },
    updateNumberVoters() {
      if (this.blockchainIsConnected()) {
        window.bc.contract().getNbVoters((err, nb) => {
          this.nbVoters = nb;
        });
      }
    },
    nextPhase() {
      this.msgStatus = "";
      if (this.blockchainIsConnected()) {
        window.bc.getMainAccount()
        .then(account => {
          window.bc.contract().getVotingStatus((err, status) => {
            if (status == 0) {
              window.bc.contract().startProposalsRegistration({ from: account }, (error, res) => {
                if (error) reject(error);
              });
            }
            else if (status == 1) {
              window.bc.contract().stopProposalsRegistration({ from: account }, (error, res) => {
                if (error) reject(error);
              });
            }
            else if (status == 2) {
              window.bc.contract().startVotingSession({ from: account }, (error, res) => {
                if (error) reject(error);
              });
            }
            else if (status == 3) {
              window.bc.contract().stopVotingSession({ from: account }, (error, res) => {
                if (error) reject(error);
              });
            }
            else if (status == 4) {
              window.bc.contract().stopProposalsRegistration({ from: account }, (error, res) => {
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
          console.log("Nb proposals : " + nbProposal);
          for (let i=1;i<=nbProposal;i++) {
            window.bc.contract().getProposal(i, (err, strProposal) => {
              console.log(strProposal);
              var found=false;
              for (let j=0;j<this.proposals.length;j++) {
                if (this.proposals[j].id == i) {
                  found = true;
                  break;
                }
              }  
              if (!found)
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
    confirmVote() {
      console.log("vote selected : " + this.selectedVote.id);
      if (this.blockchainIsConnected()) {
        window.bc.getMainAccount()
        .then(account => {
            window.bc.contract().voting(this.selectedVote.id, { from: account }, (error, txHash) => {
                if (error) {
                  this.msgStatus = "Error. Check console logs";
                  console.error(error);
                }
                else
                  this.msgStatus = "User Vote Sibmitted";
                //resolve(res);
            });
        })
        .catch(error => reject(error));
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
