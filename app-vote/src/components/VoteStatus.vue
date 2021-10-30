<template>
  <div class="hello">
    <h1>{{ msg }}</h1>
       <div class="p-4" v-show="bcConnected && !bcConnectionError">
            Connected
            <!--<router-view></router-view>-->
        </div>
    <h1>{{ votingStatus }}</h1>
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
      msg: 'Welcome to Your Vue.js App',
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
