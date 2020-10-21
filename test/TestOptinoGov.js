const { ZERO_ADDRESS, MyData } = require('./helpers/common');
const { expect } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

describe("TestOptinoGov", function() {
  // beforeEach("Setup", async function() {
  //   console.log("    Setup");
  // const filter = {};
  //    ethers.provider.on(filter, (result) => {
  //      console.log("Event: " + result);
  //    });
  // });

  it("Standard Workflow", async function() {
    const OGToken = await ethers.getContractFactory("OGToken");
    const OGDToken = await ethers.getContractFactory("OGDToken");
    const TestToken = await ethers.getContractFactory("TestToken");
    const OptinoGov = await ethers.getContractFactory("OptinoGov");
    const myData = new MyData();
    await myData.init();

    const [ownerSigner, user1Signer, user2Signer, user3Signer] = await ethers.getSigners();

    console.log("    --- Setup 1 - Deploy OGToken, OGDToken, FEE0, then OptinoGov ---");
    var batch1 = [];
    batch1.push(OGToken.deploy("OG", "Optino Governance", 18, myData.owner, new BigNumber("40000").shiftedBy(18).toFixed(0)));
    batch1.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, myData.owner, new BigNumber("0").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE0", "Fee0", 18, myData.owner, new BigNumber("1000").shiftedBy(18).toFixed(0)));
    const [ogToken, ogdToken, fee0Token] = await Promise.all(batch1);
    var batch2 = [];
    batch2.push(OptinoGov.deploy(ogToken.address, ogdToken.address));
    const [optinoGov] = await Promise.all(batch2);
    await myData.setOptinoGovData(ogToken, ogdToken, fee0Token, optinoGov);
    await myData.printTxData("ogToken.deployTransaction", ogToken.deployTransaction);
    await myData.printTxData("ogdToken.deployTransaction", ogdToken.deployTransaction);
    await myData.printTxData("fee0Token.deployTransaction", fee0Token.deployTransaction);
    await myData.printTxData("optinoGov.deployTransaction", optinoGov.deployTransaction);
    await myData.printBalances();


    console.log("    --- Setup 2 - OGDToken.addDividendToken([ETH, FEE0]), OGDToken mint(...) permissioning ---");
    var batch3 = [];
    batch3.push(ogdToken.addDividendToken(ZERO_ADDRESS));
    batch3.push(ogdToken.addDividendToken(fee0Token.address));
    batch3.push(ogToken.setPermission(optinoGov.address, 1, true, 0));
    batch3.push(ogdToken.setPermission(optinoGov.address, 1, true, 0));
    const [addDividendToken0, addDividendToken1, setPermission1, setPermission2] = await Promise.all(batch3);
    await myData.printTxData("addDividendToken0", addDividendToken0);
    await myData.printTxData("addDividendToken1", addDividendToken1);
    await myData.printTxData("setPermission1", setPermission1);
    await myData.printTxData("setPermission2", setPermission2);
    await myData.printBalances();

    console.log("    --- Setup 3 - Transfer OGTokens, User{1..3} approve 2,000 OGTokens to OptinoGov, Owner approve 2,000 FEE0 tokens to OGDToken, Transfer OGToken and OGDToken ownership to OptinoGov ---");
    var ogTokens = new BigNumber("10000").shiftedBy(18);
    var approveTokens = new BigNumber("2000").shiftedBy(18);
    var batch4 = [];
    batch4.push(ogToken.transfer(myData.user1, ogTokens.toFixed(0)));
    batch4.push(ogToken.transfer(myData.user2, ogTokens.toFixed(0)));
    batch4.push(ogToken.transfer(myData.user3, ogTokens.toFixed(0)));
    batch4.push(ogToken.connect(user1Signer).approve(optinoGov.address, approveTokens.toFixed(0)));
    batch4.push(ogToken.connect(user2Signer).approve(optinoGov.address, approveTokens.toFixed(0)));
    batch4.push(ogToken.connect(user3Signer).approve(optinoGov.address, approveTokens.toFixed(0)));
    batch4.push(fee0Token.approve(ogdToken.address, approveTokens.toFixed(0)));
    batch4.push(ogToken.transferOwnership(optinoGov.address));
    batch4.push(ogdToken.transferOwnership(optinoGov.address));
    const [transfer1, transfer2, transfer3, approve1, approve2, approve3, approve4, transferOwnership1, transferOwnership2] = await Promise.all(batch4);
    await myData.printTxData("transfer1", transfer1);
    await myData.printTxData("transfer2", transfer2);
    await myData.printTxData("transfer3", transfer3);
    await myData.printTxData("approve1", approve1);
    await myData.printTxData("approve2", approve2);
    await myData.printTxData("approve3", approve3);
    await myData.printTxData("approve4", approve4);
    await myData.printTxData("transferOwnership1", transferOwnership1);
    await myData.printTxData("transferOwnership2", transferOwnership2);
    await myData.printBalances();

    console.log("    --- Test 1 - User{1,2} delegate to User3---");
    var batch5 = [];
    batch5.push(optinoGov.connect(user1Signer).delegate(myData.user3));
    batch5.push(optinoGov.connect(user2Signer).delegate(myData.user3));
    const [delegate1, delegate2] = await Promise.all(batch5);
    await myData.printTxData("delegate1", delegate1);
    await myData.printTxData("delegate2", delegate2);
    await myData.printBalances();

    console.log("    --- Test 2 - User{1..3} commit OGTokens for {5, 50, 500} seconds duration ---");
    var lockTokens = new BigNumber("1000").shiftedBy(18);
    var batch6 = [];
    batch6.push(optinoGov.connect(user1Signer).commit(lockTokens.toFixed(0), 5));
    batch6.push(optinoGov.connect(user2Signer).commit(lockTokens.toFixed(0), 50));
    batch6.push(optinoGov.connect(user3Signer).commit(lockTokens.toFixed(0), 500));
    const [commit1, commit2, commit3] = await Promise.all(batch6);
    await myData.printTxData("commit1", commit1);
    await myData.printTxData("commit2", commit2);
    await myData.printTxData("commit3", commit3);
    await myData.printBalances();

    console.log("    --- Test 3 - User{2} commit again for {55} seconds duration ---");
    var batch7 = [];
    batch7.push(optinoGov.connect(user2Signer).commit(lockTokens.toFixed(0), 55));
    const [commit4] = await Promise.all(batch7);
    await myData.printTxData("commit4", commit4);
    await myData.printBalances();

    console.log("    --- Test 4 - User1 collecting rewards, user2 collecting and committing rewards leaving duration unchanged, user3 collecting and committing rewards and extending duration ---");
    var batch8 = [];
    batch8.push(optinoGov.connect(user1Signer).collectReward(false, 0));
    batch8.push(optinoGov.connect(user2Signer).collectReward(true, 0));
    batch8.push(optinoGov.connect(user3Signer).collectReward(true, 5000));
    const [collectReward1, collectReward2, collectReward3] = await Promise.all(batch8);
    await myData.printTxData("collectReward1", collectReward1);
    await myData.printTxData("collectReward2", collectReward2);
    await myData.printTxData("collectReward3", collectReward3);
    await myData.printBalances();

    console.log("    --- Test 5 - Owner collecting rewards on behalf of user1 for a % fee ---");
    myData.pause("Waiting", 5);
    var batch9 = [];
    batch9.push(myData.optinoGov.collectRewardFor(myData.user1));
    const [collectRewardFor1] = await Promise.all(batch9);
    await myData.printTxData("collectRewardFor1", collectRewardFor1);
    await myData.printBalances();

    console.log("    --- Test 6 - Owner deposits dividends of 10 ETH and 100 FEE ---");
    var depositFee1Tokens = new BigNumber("10").shiftedBy(18);
    var depositFee2Tokens = new BigNumber("100").shiftedBy(18);
    var batch10 = [];
    batch10.push(ogdToken.depositDividend(ZERO_ADDRESS, depositFee1Tokens.toFixed(0), { value: depositFee1Tokens.toFixed(0) }));
    batch10.push(ogdToken.depositDividend(myData.fee0Token.address, depositFee2Tokens.toFixed(0)));
    const [depositDividendFee1, depositDividendFee2] = await Promise.all(batch10);
    await myData.printTxData("depositDividendFee1", depositDividendFee1);
    await myData.printTxData("depositDividendFee2", depositDividendFee2);
    await myData.printBalances();

    console.log("    --- Test 7 - User{1..3} withdraw ETH and FEE dividends ---");
    var batch11 = [];
    batch11.push(ogdToken.connect(user1Signer).withdrawDividends());
    batch11.push(ogdToken.connect(user2Signer).withdrawDividends());
    batch11.push(ogdToken.connect(user3Signer).withdrawDividends());
    const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(batch11);
    await myData.printTxData("withdrawDividends1", withdrawDividends1);
    await myData.printTxData("withdrawDividends2", withdrawDividends2);
    await myData.printTxData("withdrawDividends3", withdrawDividends3);
    await myData.printBalances();

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
