const { ZERO_ADDRESS, MyData } = require('./helpers/common');
const { expect } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

describe("TestOGDToken", function() {
  // beforeEach("Setup", async function() {
  //   console.log("    Setup");
  // });

  it("Standard Workflow", async function() {
    const OGDToken = await ethers.getContractFactory("OGDToken");
    const TestToken = await ethers.getContractFactory("TestToken");
    const myData = new MyData();
    await myData.init();

    const [owner, user1, user2, user3] = await ethers.getSigners();

    // const filter = {};
    // ethers.provider.on(filter, (result) => {
    //   console.log("Event: " + result);
    // });

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

    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");

    await greeter.deployed();
    expect(await greeter.greet()).to.equal("Hello, world!");

    await greeter.setGreeting("Hola, mundo!");
    // await greeter.connect(myData.user1).setGreeting("Hola, mundo!");
    expect(await greeter.greet()).to.equal("Hola, mundo!");

    // await ethers.provider.getLogs({}).then((data) => {
    //   console.log("getLogs: " + util.inspect(data));
    // });
  });
});
