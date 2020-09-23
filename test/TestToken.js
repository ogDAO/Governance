const { MyData, ZERO_ADDRESS, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
const util = require('util');
const ethers = require('ethers');

function TestTokenTests(myData) {

  // this.myData = myData;

  it('Test getBlockNumber 1 a', async () => {
    // console.log("TestToken.js - util.inspect(myData): " + util.inspect(myData));
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("it.block number 1 => " + result) });
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("Test getBlockNumber 1 - blockNumber: " + blockNumber);
    // await web3.eth.sendTransaction({ value: "100000000000000000", from: myData.owner, to: myData.user1 });

    // this.TestToken.transfer.sendTransaction(myData.user1, "123", { from: myData.owner });
    // console.log(this.TestToken);
    // console.log(JSON.stringify(this.TestToken));
    // await this.TestToken.transfer(myData.user1, "123");

    await myData.printBalances();
    const testToken = myData.tokenContracts[0];
    // console.log("TestToken.js - util.inspect(testToken): " + util.inspect(testToken));
    const tx1 = web3.eth.sendTransaction({ value: new BigNumber("10").shiftedBy(18), from: myData.owner, to: myData.user1 });
    const tx2 = web3.eth.sendTransaction({ value: new BigNumber("10").shiftedBy(18), from: myData.owner, to: myData.user2 });
    const tx3 = web3.eth.sendTransaction({ value: new BigNumber("10").shiftedBy(18), from: myData.owner, to: myData.user3 });
    const tx4 = testToken.transfer(myData.user1, new BigNumber("100").shiftedBy(18), { from: myData.owner });
    const tx5 = testToken.transfer(myData.user2, new BigNumber("100").shiftedBy(18), { from: myData.owner });
    const tx6 = testToken.transfer(myData.user3, new BigNumber("100").shiftedBy(18), { from: myData.owner });
    await Promise.all([tx1, tx2, tx3, tx4, tx5, tx6]);
    await myData.printBalances();
    assert.equal(1, 1, "1 1=1");
  });

  it('Test getBlockNumber 2 b', async () => {
    const message = "Hello";
    console.log("Test getBlockNumber 2 b - message: " + message);

    // test account 0xa00Af22D07c87d96EeeB0Ed583f8F6AC7812827E
    let privateKey = '0x56554ba7c55d35844ffe3b132ad064faa810780fe73b952f8c8593facfcb1eaa';
    let wallet = new ethers.Wallet(privateKey);
    console.log("Test getBlockNumber 2 b - wallet: " + util.inspect(wallet));
    let ethersSignature = await wallet.signMessage(message);
    console.log("Test getBlockNumber 2 b - ethersSignature: " + ethersSignature);
    // const ethersSigningAccount = await web3.eth.accounts.recover(message, ethersSignature, false);
    const ethersSigningAccount = ethers.utils.verifyMessage(message, ethersSignature);
    console.log("Test getBlockNumber 2 b - ethersSigningAccount: " + ethersSigningAccount);

    const web3jsSignature = await web3.eth.sign(message, myData.owner);
    console.log("Test getBlockNumber 2 b - web3jsSignature: " + web3jsSignature);
    const web3jsSigningAccount = await web3.eth.accounts.recover(message, web3jsSignature, false);
    console.log("Test getBlockNumber 2 b - web3jsSigningAccount: " + web3jsSigningAccount);
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("it.block number 2 => " + result) });
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("Test getBlockNumber 2 - blockNumber: " + blockNumber);
    // await myData.printBalances();
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
    console.log("TestToken.TestTokenTests.beforeEach()");
    // myData = new MyData(_accounts);
    // await myData.setBaseBlock();
    // var blockNumber = await web3.eth.getBlockNumber();
    // console.log("beforeEach - blockNumber: " + blockNumber);
    // web3.eth.getBlockNumber(function(error, result) { if (!error) console.log("beforeEach.block number => " + result) });
    // console.log("beforeEach.Deploying TestToken");
    // this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new web3.utils.BN("1000000000000000000000000"), { from: myData.owner, gas: 2000000 });
    // console.log("beforeEach.Deployed TestToken.address: " + this.TestToken.address);
    // await myData.addToken(this.TestToken);
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

  // describe("TestToken behavior tests", function () {
    // web3 not available
    // const myData = new MyData(_accounts);
    // myData.setBaseBlock();
    // console.log("TestToken.test.js: describe(TestToken behavior tests)");

    // myData.printBalances();
  // });
}


module.exports = {
    TestTokenTests
}
