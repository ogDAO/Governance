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
    console.log("RESULT: --- Setup - Deploy OGToken, Fee{0..2} ---");
    var batch1 = [];
    // "OGD", "Optino Governance Dividend", "18", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "10000000000000000000000"
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 3000000 }));
    batch1.push(TestToken.new("FEE0", "Fee0", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE1", "Fee1", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE2", "Fee2", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogdToken, fee0Token, fee1Token, fee2Token] = await Promise.all(batch1);

    console.log("RESULT: --- Setup - OGToken.addDividendTokens for ETH and Fee0 ---");
    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    var approveFee0Tokens = new BigNumber("10000").shiftedBy(18);
    // batch2.push(ogdToken.mint(myData.user1, ogdTokens, { from: myData.owner }));
    // batch2.push(ogdToken.mint(myData.user2, ogdTokens, { from: myData.owner }));
    // batch2.push(ogdToken.mint(myData.user3, ogdTokens, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(fee0Token.address, { from: myData.owner }));
    // batch2.push(feeToken.approve(ogdToken.address, approveFee0Tokens, { from: myData.owner }));
    // const [mint1, mint2, mint3, addDividendToken1, addDividendToken2, ownerApproveFee0Tokens] = await Promise.all(batch2);
    const [addDividendToken0, addDividendToken1] = await Promise.all(batch2);

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

    await myData.setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token);
  });

  it('Test OGDToken workflow', async () => {
    await myData.printBalances();
    // Have to manually run web3.personal.unlockAccount(eth.accounts[x], "") in geth console await myData.unlockAccounts("");

    console.log("RESULT: --- Mint 10,000 OGD tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
    var batch1 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    var approveFee0Tokens = new BigNumber("100").shiftedBy(18);
    var approveFee1Tokens = new BigNumber("1000").shiftedBy(18);
    var approveFee2Tokens = new BigNumber("10000").shiftedBy(18);
    batch1.push(myData.ogdToken.mint(myData.user1, ogdTokens, { from: myData.owner }));
    batch1.push(myData.ogdToken.mint(myData.user2, ogdTokens, { from: myData.owner }));
    batch1.push(myData.ogdToken.mint(myData.user3, ogdTokens, { from: myData.owner }));
    batch1.push(myData.fee0Token.approve(myData.ogdToken.address, approveFee0Tokens, { from: myData.owner }));
    batch1.push(myData.fee1Token.approve(myData.ogdToken.address, approveFee1Tokens, { from: myData.owner }));
    batch1.push(myData.fee2Token.approve(myData.ogdToken.address, approveFee2Tokens, { from: myData.owner }));
    const [mint1, mint2, mint3, ownerApproveFee0Tokens, ownerApproveFee1Tokens, ownerApproveFee2Tokens] = await Promise.all(batch1);

    console.log("RESULT: --- Owner deposits dividends of 100 FEE0 and 10 ETH ---");
    var batch2 = [];
    var depositFee0Tokens = new BigNumber("100").shiftedBy(18);
    var depositFeeETH = new BigNumber("10").shiftedBy(18);
    batch2.push(myData.ogdToken.depositDividend(myData.fee0Token.address, depositFee0Tokens, { from: myData.owner }));
    batch2.push(myData.ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH, { from: myData.owner, value: depositFeeETH }));
    const [depositDividendFee0, depositDividendETH] = await Promise.all(batch2);

    await myData.printBalances();

    console.log("RESULT: --- User1 dummy transfer to same account ---");
    var batch3 = [];
    batch3.push(myData.ogdToken.transfer(myData.user2, "1", { from: myData.user2 }));
    const [dummyTransfer] = await Promise.all(batch3);

    console.log("RESULT: --- User{1..3} withdraw 33.333333333333333333 FEE0 and 3.333333333333333333 ETH ---");
    var batch4 = [];
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    // batch4.push(myData.ogdToken.burn(new BigNumber("10").shiftedBy(18), { from: myData.user3 }));
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch4);

    await myData.printBalances();

    console.log("RESULT: --- Add Fee{1..2} Dividend Token ---");
    var batch5 = [];
    batch5.push(myData.ogdToken.addDividendToken(myData.fee1Token.address, { from: myData.owner }));
    batch5.push(myData.ogdToken.addDividendToken(myData.fee2Token.address, { from: myData.owner }));
    const [addDividendToken2, addDividendToken3] = await Promise.all(batch5);

    console.log("RESULT: --- Owner deposits dividends of 1,000 FEE1 and 10,000 FEE2 ---");
    var batch6 = [];
    var depositFee1Tokens = new BigNumber("1000").shiftedBy(18);
    var depositFee2Tokens = new BigNumber("10000").shiftedBy(18);
    batch6.push(myData.ogdToken.depositDividend(myData.fee1Token.address, depositFee1Tokens, { from: myData.owner }));
    batch6.push(myData.ogdToken.depositDividend(myData.fee2Token.address, depositFee2Tokens, { from: myData.owner }));
    const [depositDividendFee1, depositDividendFee2] = await Promise.all(batch6);

    await myData.printBalances();

    console.log("RESULT: --- User{1..3} withdraw 333.333333333333333333 FEE1 and 3333.333333333333333333 FEE2 ---");
    var batch7 = [];
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    const [withdrawDividends4, withdrawDividends5, withdrawDividends6] = await Promise.all(batch7);

    await myData.printBalances();

    console.log("RESULT: --- User2 transfer 1 OGD to User3 ---");
    var batch8 = [];
    batch8.push(myData.ogdToken.transfer(myData.user3, "1", { from: myData.user2 }));
    const [transfer1] = await Promise.all(batch8);

    console.log("RESULT: mint1.receipt.gasUsed: " + mint1.receipt.gasUsed);
    console.log("RESULT: depositDividendFee0.receipt.gasUsed: " + depositDividendFee0.receipt.gasUsed);
    console.log("RESULT: depositDividendETH.receipt.gasUsed: " + depositDividendETH.receipt.gasUsed);
    console.log("RESULT: dummyTransfer.receipt.gasUsed: " + dummyTransfer.receipt.gasUsed);
    console.log("RESULT: withdrawDividends1.receipt.gasUsed: " + withdrawDividends1.receipt.gasUsed);
    console.log("RESULT: addDividendToken2.receipt.gasUsed: " + addDividendToken2.receipt.gasUsed);
    console.log("RESULT: depositDividendFee1.receipt.gasUsed: " + depositDividendFee1.receipt.gasUsed);
    console.log("RESULT: transfer1.receipt.gasUsed: " + transfer1.receipt.gasUsed);
    // console.log("RESULT: dummyTransfer: " + util.inspect(dummyTransfer.logs));
    // myData.ogdToken.getPastEvents("allEvents", { fromBlock: 0, toBlock: "latest" }).then(console.log);

    assert.equal(2, 2, "2 2=2");
  });

  describe("Test OGDToken tests", function () {
    // web3 not available yet
    console.log("TestOGDToken.test.js: describe(OGToken behavior tests)");
    // TestTokenTests(myData);
  });
})
