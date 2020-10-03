const { MyData, ZERO_ADDRESS, OGToken, OGDToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');

// const { TestTokenTests } = require('./TestToken.js');

contract('Test OGDToken', async _accounts => {

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

  beforeEach('Test OGDToken beforeEach', async function () {
    // this.myData = new MyData(_accounts);
    await myData.setBaseBlock();
    var batch1 = [];
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogdToken, feeToken] = await Promise.all(batch1);

    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(ogdToken.mint(myData.user1, ogdTokens, { from: myData.owner }));
    batch2.push(ogdToken.mint(myData.user2, ogdTokens, { from: myData.owner }));
    batch2.push(ogdToken.mint(myData.user3, ogdTokens, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken("0x0000000000000000000000000000000000000000", { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(feeToken.address, { from: myData.owner }));
    const [mint1, mint2, mint3, addDividendToken1, addDividendToken2] = await Promise.all(batch2);

    // var batch3 = [];
    // batch3.push(ogToken.setPermission(optinoGov.address, 1, true, 0, { from: myData.owner }));
    // batch3.push(ogdToken.setPermission(optinoGov.address, 1, true, 0, { from: myData.owner }));
    // const [ogTokenSetPermission, ogdTokenSetPermission] = await Promise.all(batch3);
    //
    // var batch4 = [];
    // batch4.push(ogToken.transferOwnership(optinoGov.address));
    // batch4.push(ogdToken.transferOwnership(optinoGov.address));
    // const [ogTokenTransferOwnership, ogdTokenTransferOwnership] = await Promise.all(batch4);

    await myData.setOGDTokenData(ogdToken, feeToken);
  });

  it('Test OGDToken Lock Tokens', async () => {
    await myData.printBalances();
    // Have to manually run web3.personal.unlockAccount(eth.accounts[x], "") in geth console await myData.unlockAccounts("");

    // var lockDuration = 500;
    // var lockTokens = new BigNumber("1000").shiftedBy(18);
    // var batch1 = [];
    // batch1.push(myData.ogToken.approve(myData.optinoGov.address, lockTokens, { from: myData.user1 }));
    // batch1.push(myData.ogToken.approve(myData.optinoGov.address, lockTokens, { from: myData.user2 }));
    // batch1.push(myData.ogToken.approve(myData.optinoGov.address, lockTokens, { from: myData.user3 }));
    // await Promise.all(batch1);
    //
    // var batch2 = [];
    // batch2.push(myData.optinoGov.lock(lockTokens, lockDuration, { from: myData.user1 }));
    // batch2.push(myData.optinoGov.lock(lockTokens, lockDuration, { from: myData.user2 }));
    // batch2.push(myData.optinoGov.lock(lockTokens, lockDuration, { from: myData.user3 }));
    // await Promise.all(batch2);
    // await myData.printBalances();
    assert.equal(2, 2, "2 2=2");
  });

  describe("Test OGDToken tests", function () {
    // web3 not available yet
    console.log("TestOGDToken.test.js: describe(OGToken behavior tests)");
    // TestTokenTests(myData);
  });
})
