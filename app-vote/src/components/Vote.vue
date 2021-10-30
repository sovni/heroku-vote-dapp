<template>
  <div class="hello">
    <h1>{{ msg }}</h1>
    <div class="p-4" v-show="this.votingStatus == 0">
        <h2>Vote Phase: User Registration</h2>
        <form @submit.prevent="registerVoter">
            <InputText v-model="voterAddress" type="text"/>
            <Button label="Enregistrer" class="p-button-sm p-ml-4"  @click="registerVoter()"/>
        </form>        
        <Listbox :options="voters" optionLabel="Adresses" style="width:15rem" />        
        <Button label="Finish" @click="nextPhase()" />
        <div> {{ msgStatus }} </div>
    </div>
    <div class="p-4" v-show="this.votingStatus == 1">
        <h2>Vote Phase: Proposal Registration Phase</h2>
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

export default {
  name: 'VoteStatus',
  mixins: [mixin],
  components: {
      InputText,
      Button
  },
  data () {
    return {
      msg: 'Welcome to Your Vue.js Vote dApp',
      votingStatus: 1000,
      voterAddress: '',
      msgStatus: '',
      tmoConn: null // contain the intervalID given by setInterval
    }
  },

  methods: {
    getVotingStatus() {
      if (this.blockchainIsConnected()) {
        //clearInterval(this.tmoConn);
        window.bc.contract().getVotingStatus((err, status) => {
          this.votingStatus = status;
        });
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

                resolve(res);
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
                    this.msgStatus = "User Registered";
                    this.voterAddress = "";
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
        this.getVotingStatus();
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
