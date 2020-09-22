// const Web3 = require('web3');
// const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

const { MyData, ZERO_ADDRESS, TestToken, printBalancesOld } = require('./helpers/common');
const BigNumber = require('bignumber.js');

contract('TestToken', async _accounts => {

  let myData;

  it('Test getBlockNumber 1', async () => {
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("it.block number 1 => " + result) });
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("Test getBlockNumber 1 - blockNumber: " + blockNumber);
    await web3.eth.sendTransaction({ value: "100000000000000000", from: myData.owner, to: myData.user1 });
    await myData.printBalances();
    assert.equal(1, 1, "1 1=1");
  });

  it('Test getBlockNumber 2', async () => {
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("it.block number 2 => " + result) });
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("Test getBlockNumber 2 - blockNumber: " + blockNumber);
    await myData.printBalances();
    assert.equal(2, 2, "2 2=2");
  });

  // const myData = new MyData(_accounts);
  // const owner = myData.owner
  // const tokenHolder = myData.user
  // const otherAccount = myData.user2
  //

  // it("...should...", async () => {
    // const accountABalance = await web3.eth.getBalance(accountA);
    /// ...
  // });

  beforeEach(async function () {
    myData = new MyData(_accounts);
    await myData.setBaseBlock();
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("beforeEach - blockNumber: " + blockNumber);
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("beforeEach.block number => " + result) });
    // console.log("beforeEach.Deploying TestToken");
    this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new web3.utils.BN("1000"), { from: myData.owner, gas: 2000000 });
    console.log("beforeEach.Deployed TestToken.address: " + this.TestToken.address);
    await myData.addToken(this.TestToken);
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
    // web3 not available
    // const myData = new MyData(_accounts);
    // myData.setBaseBlock();
    console.log("TestToken.test.js: describe(TestToken behavior tests)");

    // myData.printBalances();
  });
})
