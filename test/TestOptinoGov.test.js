const { MyData, ZERO_ADDRESS, OGToken, OGDToken, OptinoGov, TestToken, printBalances } = require('./helpers/common');
const BigNumber = require('bignumber.js');
// const util = require('util');

// const { TestTokenTests } = require('./TestToken.js');

contract('Test OptinoGov', async _accounts => {

  const myData = new MyData(_accounts);

  beforeEach('Test OptinoGov beforeEach', async function () {
    await myData.setBaseBlock();

    console.log("RESULT: --- Setup 1 - Deploy OGToken, OGDToken, FEE ---");
    var batch1 = [];
    batch1.push(OGToken.new("OG", "Optino Governance", 18, myData.owner, new BigNumber("40000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    batch1.push(OGDToken.new("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18), { from: myData.owner, gas: 3000000 }));
    batch1.push(TestToken.new("FEE", "Fee", 18, myData.owner, new BigNumber("10000").shiftedBy(18), { from: myData.owner, gas: 2000000 }));
    const [ogToken, ogdToken, feeToken] = await Promise.all(batch1);

    console.log("RESULT: --- Setup 2 - Deploy OptinoGov, Distributed OGTokens, AddDividendTokens([0x00, FEE]) ---");
    var batch2 = [];
    var ogTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(OptinoGov.new(ogToken.address, ogdToken.address, { from: myData.owner, gas: 5000000 }));
    batch2.push(ogToken.transfer(myData.user1, ogTokens, { from: myData.owner }));
    batch2.push(ogToken.transfer(myData.user2, ogTokens, { from: myData.owner }));
    batch2.push(ogToken.transfer(myData.user3, ogTokens, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS, { from: myData.owner }));
    batch2.push(ogdToken.addDividendToken(feeToken.address, { from: myData.owner }));
    const [optinoGov, mint1, mint2, mint3, addDividendToken1, addDividendToken2] = await Promise.all(batch2);

    console.log("RESULT: --- Setup 3 - Permission OptinoGov to mint OGTokens and OGDTokens ---");
    var batch3 = [];
    batch3.push(ogToken.setPermission(optinoGov.address, 1, true, 0, { from: myData.owner }));
    batch3.push(ogdToken.setPermission(optinoGov.address, 1, true, 0, { from: myData.owner }));
    // batch3.push(ogToken.setPermission(myData.owner, 1, false, 0, { from: myData.owner }));
    // batch3.push(ogdToken.setPermission(myData.owner, 1, false, 0, { from: myData.owner }));
    const [ogTokenSetPermission, ogdTokenSetPermission] = await Promise.all(batch3);

    console.log("RESULT: --- Setup 4 - Transfer ownership of OGToken and OGDToken to OptinoGov ---");
    var batch4 = [];
    batch4.push(ogToken.transferOwnership(optinoGov.address, { from: myData.owner }));
    batch4.push(ogdToken.transferOwnership(optinoGov.address, { from: myData.owner }));
    const [ogTokenTransferOwnership, ogdTokenTransferOwnership] = await Promise.all(batch4);

    await myData.setOptinoGovData(ogToken, ogdToken, feeToken, optinoGov);
  });

  it('Test OptinoGov Commit Tokens', async () => {
    await myData.printBalances();
    // Have to manually run web3.personal.unlockAccount(eth.accounts[x], "") in geth console await myData.unlockAccounts("");

    console.log("RESULT: --- Test 1 - User{1..3} approve 1000 OGTokens to OptinoGov. Owner approves 1000 FEE to OGDToken ---");
    var approveTokens = new BigNumber("1000").shiftedBy(18);
    var batch1 = [];
    batch1.push(myData.ogToken.approve(myData.optinoGov.address, approveTokens, { from: myData.user1 }));
    batch1.push(myData.ogToken.approve(myData.optinoGov.address, approveTokens, { from: myData.user2 }));
    batch1.push(myData.ogToken.approve(myData.optinoGov.address, approveTokens, { from: myData.user3 }));
    batch1.push(myData.fee0Token.approve(myData.ogdToken.address, approveTokens, { from: myData.owner }));
    await Promise.all(batch1);

    console.log("RESULT: --- Test 2 - User{1..3} commit OGTokens for {5, 50, 500} seconds duration ---");
    var lockTokens = new BigNumber("1000").shiftedBy(18);
    var batch2 = [];
    batch2.push(myData.optinoGov.commit(lockTokens, 5, { from: myData.user1 }));
    batch2.push(myData.optinoGov.commit(lockTokens, 50, { from: myData.user2 }));
    batch2.push(myData.optinoGov.commit(lockTokens, 500, { from: myData.user3 }));
    await Promise.all(batch2);
    await myData.printBalances();

    console.log("RESULT: --- Test 3 - User1 collecting rewards, user2 collecting and committing rewards leaving duration unchanged, user3 collecting and committing rewards and extending duration ---");
    var batch3 = [];
    batch3.push(myData.optinoGov.collectReward(false, 0, { from: myData.user1 }));
    batch3.push(myData.optinoGov.collectReward(true, 0, { from: myData.user2 }));
    batch3.push(myData.optinoGov.collectReward(true, 5000, { from: myData.user3 }));
    await Promise.all(batch3);
    const [collectRewardFor1, collectRewardFor2, collectRewardFor3] = await Promise.all(batch3);
    await myData.printBalances();

    console.log("RESULT: --- Test 4 - Owner collecting rewards on behalf of user1 for a % fee ---");
    myData.pause("Waiting", 5);
    var batch4 = [];
    batch4.push(myData.optinoGov.collectRewardFor(myData.user1, { from: myData.owner }));
    const [collectRewardFor4] = await Promise.all(batch4);
    await myData.printBalances();

    console.log("RESULT: --- Test 5 - Owner deposits dividends of 10 ETH and 100 FEE ---");
    var batch5 = [];
    var depositFee1Tokens = new BigNumber("10").shiftedBy(18);
    var depositFee2Tokens = new BigNumber("100").shiftedBy(18);
    batch5.push(myData.ogdToken.depositDividend(ZERO_ADDRESS, depositFee1Tokens, { value: depositFee1Tokens, from: myData.owner }));
    batch5.push(myData.ogdToken.depositDividend(myData.fee0Token.address, depositFee2Tokens, { from: myData.owner }));
    const [depositDividendFee1, depositDividendFee2] = await Promise.all(batch5);
    await myData.printBalances();

    console.log("RESULT: --- User{1..3} withdraw ETH and FEE dividends ---");
    var batch6 = [];
    batch6.push(myData.ogdToken.withdrawDividends({ from: myData.user1 }));
    batch6.push(myData.ogdToken.withdrawDividends({ from: myData.user2 }));
    batch6.push(myData.ogdToken.withdrawDividends({ from: myData.user3 }));
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch6);

    await myData.printBalances();

    console.log("RESULT: collectRewardFor1.receipt.gasUsed: " + collectRewardFor1.receipt.gasUsed);
    console.log("RESULT: collectRewardFor2.receipt.gasUsed: " + collectRewardFor2.receipt.gasUsed);
    console.log("RESULT: collectRewardFor3.receipt.gasUsed: " + collectRewardFor3.receipt.gasUsed);
    console.log("RESULT: collectRewardFor4.receipt.gasUsed: " + collectRewardFor4.receipt.gasUsed);
    console.log("RESULT: depositDividendFee1.receipt.gasUsed: " + depositDividendFee1.receipt.gasUsed);
    console.log("RESULT: depositDividendFee2.receipt.gasUsed: " + depositDividendFee2.receipt.gasUsed);
    console.log("RESULT: withdrawDividends1.receipt.gasUsed: " + withdrawDividends1.receipt.gasUsed);
    console.log("RESULT: withdrawDividends2.receipt.gasUsed: " + withdrawDividends2.receipt.gasUsed);
    console.log("RESULT: withdrawDividends3.receipt.gasUsed: " + withdrawDividends3.receipt.gasUsed);

    assert.equal(2, 2, "2 2=2");
  });

  describe("Test OptinoGov tests", function () {
    // web3 not available yet
    console.log("TestToken.test.js: describe(TestToken behavior tests)");
    // TestTokenTests(myData);
  });
})
