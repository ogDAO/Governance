const { MyData, ZERO_ADDRESS, OGToken, OGDToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions');
// const util = require('util');

contract('Test OGDToken', async _accounts => {

  const myData = new MyData(_accounts);

  beforeEach('Test OGDToken beforeEach', async function () {
    await myData.setBaseBlock();
    console.log("RESULT: --- Setup 1 - Deploy OGToken, Fee{0..2} ---");
    var batch1 = [];
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 3000000 }));
    batch1.push(TestToken.new("FEE0", "Fee0", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE1", "Fee1", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(TestToken.new("FEE2", "Fee2", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogdToken, fee0Token, fee1Token, fee2Token] = await Promise.all(batch1);
    let ogdTokenTx = await truffleAssert.createTransactionResult(ogdToken, ogdToken.transactionHash);
    let fee0TokenTx = await truffleAssert.createTransactionResult(fee0Token, fee0Token.transactionHash);
    let fee1TokenTx = await truffleAssert.createTransactionResult(fee1Token, fee1Token.transactionHash);
    let fee2TokenTx = await truffleAssert.createTransactionResult(fee2Token, fee2Token.transactionHash);
    myData.printTxData("ogdTokenTx", ogdTokenTx);
    myData.printTxData("fee0TokenTx", fee0TokenTx);
    myData.printTxData("fee1TokenTx", fee1TokenTx);
    myData.printTxData("fee2TokenTx", fee2TokenTx);

    console.log("RESULT: --- Setup 2 - OGToken.addDividendTokens for ETH and Fee0 ---");
    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(fee0Token.address, { from: myData.owner }));
    batch2.push(ogdToken.setPermission(myData.owner, 1, true, 0, { from: myData.owner }));
    const [addDividendToken0, addDividendToken1, setPermission1] = await Promise.all(batch2);
    myData.printTxData("addDividendToken0", addDividendToken0);
    myData.printTxData("addDividendToken1", addDividendToken1);
    myData.printTxData("setPermission1", setPermission1);

    await myData.setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token);
  });

  it('Test OGDToken workflow', async () => {
    await myData.printBalances();
    // Have to manually run web3.personal.unlockAccount(eth.accounts[x], "") in geth console await myData.unlockAccounts("");

    console.log("RESULT: --- Test 1 - Mint 10,000 OGD tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
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
    myData.printTxData("mint1", mint1);
    myData.printTxData("mint2", mint2);
    myData.printTxData("mint3", mint3);
    myData.printTxData("ownerApproveFee0Tokens", ownerApproveFee0Tokens);
    myData.printTxData("ownerApproveFee1Tokens", ownerApproveFee1Tokens);
    myData.printTxData("ownerApproveFee2Tokens", ownerApproveFee2Tokens);

    console.log("RESULT: --- Test 2 - Owner deposits dividends of 100 FEE0 and 10 ETH ---");
    var batch2 = [];
    var depositFee0Tokens = new BigNumber("100").shiftedBy(18);
    var depositFeeETH = new BigNumber("10").shiftedBy(18);
    batch2.push(myData.ogdToken.depositDividend(myData.fee0Token.address, depositFee0Tokens, { from: myData.owner }));
    batch2.push(myData.ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH, { from: myData.owner, value: depositFeeETH }));
    const [depositDividendFee0, depositDividendETH] = await Promise.all(batch2);
    await myData.printBalances();
    myData.printTxData("depositDividendFee0", depositDividendFee0);
    myData.printTxData("depositDividendETH", depositDividendETH);

    console.log("RESULT: --- Test 3 - User1 dummy transfer to same account (internal stats update) ---");
    var batch3 = [];
    batch3.push(myData.ogdToken.transfer(myData.user2, "1", { from: myData.user2 }));
    const [dummyTransfer] = await Promise.all(batch3);
    await myData.printBalances();
    myData.printTxData("dummyTransfer", dummyTransfer);

    console.log("RESULT: --- Test 4 - User{1..3} withdraw 33.333333333333333333 FEE0 and 3.333333333333333333 ETH ---");
    var batch4 = [];
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch4.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch4);
    await myData.printBalances();
    myData.printTxData("withdrawDividends1", withdrawDividends1);
    myData.printTxData("withdrawDividends2", withdrawDividends2);
    myData.printTxData("withdrawDividends3", withdrawDividends3);

    console.log("RESULT: --- Test 5 - Add Fee{1..2} Dividend Token ---");
    var batch5 = [];
    batch5.push(myData.ogdToken.addDividendToken(myData.fee1Token.address, { from: myData.owner }));
    batch5.push(myData.ogdToken.addDividendToken(myData.fee2Token.address, { from: myData.owner }));
    const [addDividendToken2, addDividendToken3] = await Promise.all(batch5);
    myData.printTxData("addDividendToken2", addDividendToken2);
    myData.printTxData("addDividendToken3", addDividendToken3);

    console.log("RESULT: --- Test 6 - Owner deposits dividends of 1,000 FEE1 and 10,000 FEE2 ---");
    var batch6 = [];
    var depositFee1Tokens = new BigNumber("1000").shiftedBy(18);
    var depositFee2Tokens = new BigNumber("10000").shiftedBy(18);
    batch6.push(myData.ogdToken.depositDividend(myData.fee1Token.address, depositFee1Tokens, { from: myData.owner }));
    batch6.push(myData.ogdToken.depositDividend(myData.fee2Token.address, depositFee2Tokens, { from: myData.owner }));
    const [depositDividendFee1, depositDividendFee2] = await Promise.all(batch6);
    await myData.printBalances();
    myData.printTxData("depositDividendFee1", depositDividendFee1);
    myData.printTxData("depositDividendFee2", depositDividendFee2);

    console.log("RESULT: --- Test 7 - User{1..3} withdraw 333.333333333333333333 FEE1 and 3333.333333333333333333 FEE2 ---");
    var batch7 = [];
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch7.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    const [withdrawDividends4, withdrawDividends5, withdrawDividends6] = await Promise.all(batch7);
    await myData.printBalances();
    myData.printTxData("withdrawDividends4", withdrawDividends4);
    myData.printTxData("withdrawDividends5", withdrawDividends5);
    myData.printTxData("withdrawDividends6", withdrawDividends6);

    console.log("RESULT: --- Test 8 - User2 transfer 1 OGD to User3 ---");
    var batch8 = [];
    batch8.push(myData.ogdToken.transfer(myData.user3, "1", { from: myData.user2 }));
    const [transfer1] = await Promise.all(batch8);
    await myData.printBalances();
    myData.printTxData("transfer1", transfer1);

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
