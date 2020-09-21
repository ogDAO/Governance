// const Web3 = require('web3');
// const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

const { MyData, ZERO_ADDRESS, TestToken, printBalancesOld } = require('./helpers/common');

contract('TestToken', async _accounts => {

  it('Test getBlockNumber', async () => {
    web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("it.block number => " + result) });
  });


    const myData = new MyData(_accounts);
    // const owner = myData.owner
    // const tokenHolder = myData.user
    // const otherAccount = myData.user2
    //

    // it("...should...", async () => {
      // const accountABalance = await web3.eth.getBalance(accountA);
      /// ...
    // });

    beforeEach(async function () {
      web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("beforeEach.block number => " + result) });
      console.log("beforeEach.Deploying TestToken");
      this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new web3.utils.BN("1000"), { from: myData.owner, gas: 2000000 });
      console.log("beforeEach.Deployed TestToken");
    //     // Set up TokenStorage
    //     this.allowances = await AllowanceSheet.new( {from:owner })
    //     this.balances = await BalanceSheet.new({ from:owner })
    //
    //     // Set up Token
    //     this.AkropolisBaseToken = await AkropolisBaseToken.new(this.balances.address, this.allowances.address, {from:owner})
    //
    //     // If Token does not own storage contracts, then the storage contracts must
    //     // transfer ownership to the token contract and then the token must claim
    //     // ownership to complete two stage ownership transfer
    //     await this.allowances.transferOwnership(this.AkropolisBaseToken.address)
    //     await this.balances.transferOwnership(this.AkropolisBaseToken.address)
    //     await this.AkropolisBaseToken.claimBalanceOwnership()
    //     await this.AkropolisBaseToken.claimAllowanceOwnership()
    });

    describe("TestToken behavior tests", function () {
      web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("describe.block number => " + result) });
      console.log("TestToken.test.js: start");
      try {
        // const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
        console.log("TestToken.test.js: web3: " + web3);
        console.log("TestToken.test.js: web3.version: " + web3.version);
        console.log("TestToken.test.js: web3.eth: " + web3.eth);
        // let balance = await web3.eth.getBalance(_accounts[0]);
        // console.log("TestToken.test.js: balance: " + balance);
        web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("block number => " + result) });
        // web3.eth.getBlockNumber(function(error, result) {
        //   console.log("getBlockNumber => " + result);
        //   if (!error) {
        //     console.log("block number => " + result);
        //   }
        // });
        // (async ()=> { await web3.eth.getBlockNumber(console.log) })()
        // console.log("TestToken.test.js: web3.eth.blockNumber(): " + web3.eth.blockNumber());
        console.log("TestToken.test.js: web3.eth.blockNumber(): " + web3.eth.blockNumber());
      } catch (e) {
        console.log("TestToken.test.js: web3 error: " + e);
      }

      // console.log("Deploying TestToken");
      // this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new web3.utils.BN("1000"), { from: myData.owner, gas: 2000000 });
      // console.log("TestToken.test.js: TestToken: " + await this.TestToken);
      // console.log("Deployed TestToken");

      // let accounts = await web3.eth.accounts[0];
      // var blockNumber = web3.eth.blockNumber();
      // console.log("TestToken.test.js: blockNumber: " + blockNumber);
      // console.log("TestToken.test.js: start: " + instance);
      // console.log("TestToken.test.js: web3: " + JSON.stringify(web3.eth.accounts[0]));
      // var blockNumber = web3.eth.blockNumber();
      // console.log("TestToken.test.js: " + JSON.stringify(blockNumber));


      // let block = await web3.eth.getBlock("latest")
      // console.log("block: " + block.number)

      // printBalancesOld(myData);

      myData.printBalances();
        // AkropolisBaseToken_Tests(owner, tokenHolder, otherAccount);
    });
})
