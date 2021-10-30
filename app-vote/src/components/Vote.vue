<template>
  <div class="hello">
    <h1>{{ msg }}</h1>
    <div class="p-4" v-show="this.votingStatus == 0">
        <h2>User Registration Phase</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 1">
        <h2>Proposal Registration Phase</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 2">
        <h2>Proposal Registration Phase Finished</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 3">
        <h2>Vote Registration Phase</h2>
    </div>
    <div class="p-4" v-show="this.votingStatus == 4">
        <h2>Vote Registration Phase Finished</h2>
    </div>                
    <div class="p-4" v-show="this.votingStatus == 5">
        <h2>Vote Results</h2>
    </div>
  </div>
</template>

<script>
// importing common function
import mixin from '../libs/mixinViews';

export default {
  name: 'VoteStatus',
  mixins: [mixin],

  data () {
    return {
      msg: 'Welcome to Your Vue.js Vote dApp',
      votingStatus: 1000,
      tmoConn: null // contain the intervalID given by setInterval
    }
  },

  methods: {
    getVotingStatus() {
      if (this.blockchainIsConnected()) {
        clearInterval(this.tmoConn);
        window.bc.contract().getVotingStatus((err, status) => {
          this.votingStatus = status;
        });
      }
   }
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
