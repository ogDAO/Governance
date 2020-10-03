const { MyData, ZERO_ADDRESS, OGToken, OGDToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
const util = require('util');
// BigNumber.prototype[require('util').inspect.custom] = BigNumber.prototype.valueOf;

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
    // "OGD", "Optino Governance Dividend", "18", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "10000000000000000000000"
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 3000000 }));
    batch1.push(TestToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogdToken, feeToken] = await Promise.all(batch1);

    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    var approveFeeTokens = new BigNumber("10000").shiftedBy(18);
    // batch2.push(ogdToken.mint(myData.user1, ogdTokens, { from: myData.owner }));
    // batch2.push(ogdToken.mint(myData.user2, ogdTokens, { from: myData.owner }));
    // batch2.push(ogdToken.mint(myData.user3, ogdTokens, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(feeToken.address, { from: myData.owner }));
    // batch2.push(feeToken.approve(ogdToken.address, approveFeeTokens, { from: myData.owner }));
    // const [mint1, mint2, mint3, addDividendToken1, addDividendToken2, ownerApproveFeeTokens] = await Promise.all(batch2);
    const [addDividendToken1, addDividendToken2] = await Promise.all(batch2);

    // var batch3 = [];
    // var depositFeeTokens = new BigNumber("100").shiftedBy(18);
    // var depositFeeETH = new BigNumber("10").shiftedBy(18);
    // batch3.push(ogdToken.depositDividends(feeToken.address, depositFeeTokens, { from: myData.owner }));
    // batch3.push(ogdToken.depositDividends(ZERO_ADDRESS, depositFeeETH, { from: myData.owner, value: depositFeeETH }));
    // const [depositDividend] = await Promise.all(batch3);

    // await myData.printBalances();
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

  it('Test OGDToken workflow', async () => {
    await myData.printBalances();
    // Have to manually run web3.personal.unlockAccount(eth.accounts[x], "") in geth console await myData.unlockAccounts("");

    console.log("RESULT: --- Mint 10,000 OGD tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
    var batch1 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    var approveFeeTokens = new BigNumber("100").shiftedBy(18);
    batch1.push(myData.ogdToken.mint(myData.user1, ogdTokens, { from: myData.owner }));
    batch1.push(myData.ogdToken.mint(myData.user2, ogdTokens, { from: myData.owner }));
    batch1.push(myData.ogdToken.mint(myData.user3, ogdTokens, { from: myData.owner }));
    batch1.push(myData.feeToken.approve(myData.ogdToken.address, approveFeeTokens, { from: myData.owner }));
    const [mint1, mint2, mint3, ownerApproveFeeTokens] = await Promise.all(batch1);

    console.log("RESULT: --- Owner deposits dividends of 100 FEE and 10 ETH ---");
    var batch2 = [];
    var depositFeeTokens = new BigNumber("100").shiftedBy(18);
    var depositFeeETH = new BigNumber("10").shiftedBy(18);
    batch2.push(myData.ogdToken.depositDividend(myData.feeToken.address, depositFeeTokens, { from: myData.owner }));
    batch2.push(myData.ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH, { from: myData.owner, value: depositFeeETH }));
    const [depositDividend] = await Promise.all(batch2);

    await myData.printBalances();

    console.log("RESULT: --- User1 dummy transfer to same account ---");
    var batch3 = [];
    batch3.push(myData.ogdToken.transfer(myData.user2, "1", { from: myData.user2 }));
    const [dummyTransfer] = await Promise.all(batch3);

    console.log("RESULT: --- User{1..3} withdraw 33.333333333333333333 FEE and 3.333333333333333333 ETH ---");
    var batch4 = [];
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    // batch4.push(myData.ogdToken.burn(new BigNumber("10").shiftedBy(18), { from: myData.user3 }));
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch4);

    // console.log("RESULT: dummyTransfer: " + util.inspect(dummyTransfer.logs));
    // myData.ogdToken.getPastEvents("allEvents", { fromBlock: 0, toBlock: "latest" }).then(console.log);

    await myData.printBalances();

    console.log("RESULT: mint1.receipt.gasUsed: " + mint1.receipt.gasUsed);
    console.log("RESULT: depositDividend.receipt.gasUsed: " + depositDividend.receipt.gasUsed);
    console.log("RESULT: dummyTransfer.receipt.gasUsed: " + dummyTransfer.receipt.gasUsed);
    console.log("RESULT: withdrawDividends1.receipt.gasUsed: " + withdrawDividends1.receipt.gasUsed);

    assert.equal(2, 2, "2 2=2");
  });

  describe("Test OGDToken tests", function () {
    // web3 not available yet
    console.log("TestOGDToken.test.js: describe(OGToken behavior tests)");
    // TestTokenTests(myData);
  });
})
