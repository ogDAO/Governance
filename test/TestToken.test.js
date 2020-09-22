const { MyData, ZERO_ADDRESS, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
const { TestTokenTests } = require('./TestToken.js');

contract('TestToken', async _accounts => {

  const myData = new MyData(_accounts);
  // this.myData = null;
  // this.TestToken = null;

  /*
  it('Test getBlockNumber 1', async () => {
    await web3.eth.sendTransaction({ value: "100000000000000000", from: this.myData.owner, to: this.myData.user1 });

    // this.TestToken.transfer.sendTransaction(myData.user1, "123", { from: myData.owner });
    // console.log(this.TestToken);
    // console.log(JSON.stringify(this.TestToken));
    // await this.TestToken.transfer(myData.user1, "123");

    await this.myData.printBalances();
    assert.equal(1, 1, "1 1=1");
  });
  it('Test getBlockNumber 2', async () => {
    await this.myData.printBalances();
    assert.equal(2, 2, "2 2=2");
  });
  */

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
    // this.myData = new MyData(_accounts);
    await myData.setBaseBlock();
    this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new web3.utils.BN("1000000000000000000000000"), { from: myData.owner, gas: 2000000 });
    console.log("    - beforeEach Deployed TestToken - address: " + this.TestToken.address);
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
    // web3 not available yet
    console.log("TestToken.test.js: describe(TestToken behavior tests)");
    TestTokenTests(myData);
  });
})
