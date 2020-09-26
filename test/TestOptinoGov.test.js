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
    var batch1 = [];
    batch1.push(OGToken.new("OG", "Optino Governance", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogToken, ogdToken, feeToken] = await Promise.all(batch1);

    var batch2 = [];
    var ogTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(OptinoGov.new(ogToken.address, ogdToken.address, { from: myData.owner, gas: 5000000 }));
    batch2.push(ogToken.mint(myData.user1, ogTokens, { from: myData.owner }));
    batch2.push(ogToken.mint(myData.user2, ogTokens, { from: myData.owner }));
    batch2.push(ogToken.mint(myData.user3, ogTokens, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken("0x0000000000000000000000000000000000000000", { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(feeToken.address, { from: myData.owner }));
    const [optinoGov, mint1, mint2, mint3, addDividendToken1, addDividendToken2] = await Promise.all(batch2);

    var batch3 = [];
    batch3.push(ogToken.transferOwnership(optinoGov.address));
    batch3.push(ogdToken.transferOwnership(optinoGov.address));
    const [ogTokenTransferOwnership, ogdTokenTransferOwnership] = await Promise.all(batch3);
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
