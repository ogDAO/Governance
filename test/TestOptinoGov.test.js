const { MyData, ZERO_ADDRESS, OFToken, OGToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
const { TestTokenTests } = require('./TestToken.js');

contract('Test OptinoGov', async _accounts => {

  const myData = new MyData(_accounts);

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

  beforeEach('Test OptinoGov beforeEach', async function () {
    // this.myData = new MyData(_accounts);
    await myData.setBaseBlock();
    const _ogToken = await OGToken.new("OG", "Optino Governance", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    const _ofToken = await OFToken.new("OF", "Optino Fee", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    const _feeToken = await OFToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    const [ogToken, ofToken, feeToken] = await Promise.all([_ogToken, _ofToken, _feeToken]);
    const optinoGov = await OptinoGov.new(ogToken.address, { from: myData.owner, gas: 5000000 });
    await myData.setOptinoGovData(ogToken, ofToken, feeToken, optinoGov);
    // this.TestToken = await TestToken.new("ABC", "Abc", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    // console.log("    - beforeEach Deployed TestToken - address: " + this.TestToken.address);
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

  it('Test getBlockNumber 2', async () => {
    await myData.printBalances();
    assert.equal(2, 2, "2 2=2");
  });

  describe("Test OptinoGov tests", function () {
    // web3 not available yet
    console.log("TestToken.test.js: describe(TestToken behavior tests)");
    // TestTokenTests(myData);
  });
})
