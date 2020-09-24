const { MyData, ZERO_ADDRESS, OGToken, OGDToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
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
    const _ogdToken = await OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    const _feeToken = await TestToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("1000000").shiftedBy(18), { from: myData.owner, gas: 2000000 });
    const [ogToken, ogdToken, feeToken] = await Promise.all([_ogToken, _ogdToken, _feeToken]);
    const optinoGov = await OptinoGov.new(ogToken.address, ogdToken.address, { from: myData.owner, gas: 5000000 });
    const _ogTokenTransferOwnership = ogToken.transferOwnership(optinoGov.address);
    const _ogdTokenTransferOwnership = ogdToken.transferOwnership(optinoGov.address);
    const [ogTokenTransferOwnership, ogdTokenTransferOwnership] = await Promise.all([_ogTokenTransferOwnership, _ogdTokenTransferOwnership]);
    await myData.setOptinoGovData(ogToken, ogdToken, feeToken, optinoGov);
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
