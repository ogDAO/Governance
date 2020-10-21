const { ZERO_ADDRESS, MyData } = require('./helpers/common');
const { expect } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

describe("TestOGDToken", function() {
  // beforeEach("Setup", async function() {
  //   console.log("    Setup");
  // const filter = {};
  //    ethers.provider.on(filter, (result) => {
  //      console.log("Event: " + result);
  //    });
  // });

  it("Standard Workflow", async function() {
    const OGDToken = await ethers.getContractFactory("OGDToken");
    const TestToken = await ethers.getContractFactory("TestToken");
    const myData = new MyData();
    await myData.init();

    const [ownerSigner, user1Signer, user2Signer, user3Signer] = await ethers.getSigners();

    console.log("    --- Setup 1 - Deploy OGDToken, FEE{0..2} ---");
    var batch1 = [];
    batch1.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE0", "Fee0", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE1", "Fee1", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE2", "Fee2", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    const [ogdToken, fee0Token, fee1Token, fee2Token] = await Promise.all(batch1);
    await myData.setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token);
    await myData.printTxData("ogdTokenTx", ogdToken.deployTransaction);
    await myData.printTxData("fee0TokenTx", fee0Token.deployTransaction);
    await myData.printTxData("fee1TokenTx", fee1Token.deployTransaction);
    await myData.printTxData("fee2TokenTx", fee2Token.deployTransaction);
    await myData.printBalances();

    console.log("    --- Setup 2 - OGDToken.addDividendTokens for ETH and FEE0, OGDToken mint(...) permissioning ---");
    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS));
    batch2.push(ogdToken.addDividendToken(fee0Token.address));
    batch2.push(ogdToken.setPermission(myData.owner, 1, true, 0));
    const [addDividendToken0, addDividendToken1, setPermission1] = await Promise.all(batch2);
    myData.printTxData("addDividendToken0", addDividendToken0);
    myData.printTxData("addDividendToken1", addDividendToken1);
    myData.printTxData("setPermission1", setPermission1);
    await myData.printBalances();

    console.log("    --- Setup 3 - Mint 10,000 OGD tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
    var batch3 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    var approveFee0Tokens = new BigNumber("100").shiftedBy(18);
    var approveFee1Tokens = new BigNumber("1000").shiftedBy(18);
    var approveFee2Tokens = new BigNumber("10000").shiftedBy(18);
    batch3.push(ogdToken.mint(myData.user1, ogdTokens.toFixed(0)));
    batch3.push(ogdToken.mint(myData.user2, ogdTokens.toFixed(0)));
    batch3.push(ogdToken.mint(myData.user3, ogdTokens.toFixed(0)));
    batch3.push(fee0Token.approve(ogdToken.address, approveFee0Tokens.toFixed(0)));
    batch3.push(fee1Token.approve(ogdToken.address, approveFee1Tokens.toFixed(0)));
    batch3.push(fee2Token.approve(ogdToken.address, approveFee2Tokens.toFixed(0)));
    const [mint1, mint2, mint3, ownerApproveFee0Tokens, ownerApproveFee1Tokens, ownerApproveFee2Tokens] = await Promise.all(batch3);
    await myData.printTxData("mint1", mint1);
    await myData.printTxData("mint2", mint2);
    await myData.printTxData("mint3", mint3);
    await myData.printTxData("ownerApproveFee0Tokens", ownerApproveFee0Tokens);
    await myData.printTxData("ownerApproveFee1Tokens", ownerApproveFee1Tokens);
    await myData.printTxData("ownerApproveFee2Tokens", ownerApproveFee2Tokens);
    await myData.printBalances();

    console.log("    --- Test 1 - Owner deposits dividends of 100 FEE0 and 10 ETH ---");
    var batch4 = [];
    var depositFee0Tokens = new BigNumber("100").shiftedBy(18);
    var depositFeeETH = new BigNumber("10").shiftedBy(18);
    batch4.push(ogdToken.depositDividend(fee0Token.address, depositFee0Tokens.toFixed(0)));
    batch4.push(ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH.toFixed(0), { value: depositFeeETH.toFixed(0) }));
    const [depositDividendFee0, depositDividendETH0] = await Promise.all(batch4);
    await myData.printTxData("depositDividendFee0", depositDividendFee0);
    await myData.printTxData("depositDividendETH0", depositDividendETH0);
    await myData.printBalances();

    console.log("    --- Test 2 - User1 dummy transfer to same account (internal stats update) ---");
    var batch5 = [];
    batch5.push(ogdToken.connect(user2Signer).transfer(myData.user2, "1"));
    const [transfer1] = await Promise.all(batch5);
    await myData.printTxData("transfer1", transfer1);
    await myData.printBalances();

    console.log("    --- Test 3 - User{1..3} withdraw 33.333333333333333333 FEE0 and 3.333333333333333333 ETH ---");
    var batch6 = [];
    batch6.push(ogdToken.connect(user1Signer).withdrawDividends());
    batch6.push(ogdToken.connect(user2Signer).withdrawDividends());
    batch6.push(ogdToken.connect(user3Signer).withdrawDividends());
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch6);
    await myData.printTxData("withdrawDividends1", withdrawDividends1);
    await myData.printTxData("withdrawDividends2", withdrawDividends2);
    await myData.printTxData("withdrawDividends3", withdrawDividends3);
    await myData.printBalances();

    console.log("    --- Test 4 - Add Fee{1..2} Dividend Token ---");
    var batch7 = [];
    batch7.push(ogdToken.addDividendToken(fee1Token.address));
    batch7.push(ogdToken.addDividendToken(fee2Token.address));
    const [addDividendToken2, addDividendToken3] = await Promise.all(batch7);
    await myData.printTxData("addDividendToken2", addDividendToken2);
    await myData.printTxData("addDividendToken3", addDividendToken3);
    await myData.printBalances();

    console.log("    --- Test 5 - Owner deposits dividends of 1,000 FEE1 and 10,000 FEE2 ---");
    var batch8 = [];
    var depositFee1Tokens = new BigNumber("1000").shiftedBy(18);
    var depositFee2Tokens = new BigNumber("10000").shiftedBy(18);
    batch8.push(ogdToken.depositDividend(fee1Token.address, depositFee1Tokens.toFixed(0)));
    batch8.push(ogdToken.depositDividend(fee2Token.address, depositFee2Tokens.toFixed(0)));
    const [depositDividendFee1, depositDividendFee2] = await Promise.all(batch8);
    await myData.printTxData("depositDividendFee1", depositDividendFee1);
    await myData.printTxData("depositDividendFee2", depositDividendFee2);
    await myData.printBalances();

    console.log("    --- Test 6 - User{1..3} withdraw 333.333333333333333333 FEE1 and 3333.333333333333333333 FEE2 ---");
    var batch9 = [];
    batch9.push(ogdToken.connect(user1Signer).withdrawDividends());
    batch9.push(ogdToken.connect(user2Signer).withdrawDividends());
    batch9.push(ogdToken.connect(user3Signer).withdrawDividends());
    const [withdrawDividends4, withdrawDividends5, withdrawDividends6] = await Promise.all(batch9);
    await myData.printTxData("withdrawDividends4", withdrawDividends4);
    await myData.printTxData("withdrawDividends5", withdrawDividends5);
    await myData.printTxData("withdrawDividends6", withdrawDividends6);
    await myData.printBalances();

    console.log("    --- Test 7 - User2 transfer 1 OGD to User3 ---");
    var batch10 = [];
    batch10.push(ogdToken.connect(user2Signer).transfer(myData.user3, new BigNumber("0.123456789123456789").shiftedBy(18).toFixed(0)));
    const [transfer2] = await Promise.all(batch10);
    await myData.printTxData("transfer2", transfer2);
    await myData.printBalances();

    const user1Fee1Balance = await fee1Token.balanceOf(myData.user1);
    console.log("user1Fee1Balance: " + user1Fee1Balance);
    expect(new BigNumber(user1Fee1Balance.toString()).toFixed(0)).to.equal(new BigNumber("333.333333333333333333").shiftedBy(18).toFixed(0));


    // const Greeter = await ethers.getContractFactory("Greeter");
    // const greeter = await Greeter.deploy("Hello, world!");
    //
    // await greeter.deployed();
    // expect(await greeter.greet()).to.equal("Hello, world!");
    //
    // await greeter.setGreeting("Hola, mundo!");
    // // await greeter.connect(myData.user1).setGreeting("Hola, mundo!");
    // expect(await greeter.greet()).to.equal("Hola, mundo!");

    // await ethers.provider.getLogs({}).then((data) => {
    //   console.log("getLogs: " + util.inspect(data));
    // });
  });
});
