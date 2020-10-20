const { ZERO_ADDRESS, MyData } = require('./helpers/common');
const { expect } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

describe("TestOGDToken", function() {
  beforeEach("Setup", async function() {
    console.log("    Setup");
  });

  it("Standard Workflow", async function() {
    const filter = {};
    ethers.provider.on(filter, (result) => {
      console.log("Event: " + result);
    });

    const OGDToken = await ethers.getContractFactory("OGDToken");
    const TestToken = await ethers.getContractFactory("TestToken");

    const myData = new MyData();
    await myData.init();

    var batch1 = [];
    batch1.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, myData.owner, "0x" + new BigNumber("0.123456789123456789").shiftedBy(18).toString(16)));
    batch1.push(TestToken.deploy("FEE0", "Fee0", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE1", "Fee1", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    batch1.push(TestToken.deploy("FEE2", "Fee2", 18, myData.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    const [ogdToken, fee0Token, fee1Token, fee2Token] = await Promise.all(batch1);
    await myData.printTxData("ogdTokenTx", ogdToken.deployTransaction, ogdToken);
    await myData.printTxData("fee0TokenTx", fee0Token.deployTransaction, fee0Token);
    await myData.printTxData("fee1TokenTx", fee1Token.deployTransaction, fee1Token);
    await myData.printTxData("fee2TokenTx", fee2Token.deployTransaction, fee2Token);

    // console.log("RESULT: --- Setup 2 - OGToken.addDividendTokens for ETH and Fee0 ---");
    var batch2 = [];
    var ogdTokens = new BigNumber("10000").shiftedBy(18);
    batch2.push(ogdToken.addDividendToken(ZERO_ADDRESS));
    batch2.push(ogdToken.addDividendToken(fee0Token.address));
    batch2.push(ogdToken.setPermission(myData.owner, 1, true, 0));
    const [addDividendToken0, addDividendToken1, setPermission1] = await Promise.all(batch2);
    // const addDividendToken0Receipt = await addDividendToken0.wait();
    // console.log("addDividendToken0Receipt: " + util.inspect(addDividendToken0Receipt));

    // myData.printTxData("addDividendToken0", addDividendToken0);
    // myData.printTxData("addDividendToken1", addDividendToken1);
    // myData.printTxData("setPermission1", setPermission1);

    await myData.setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token);

    await myData.printBalances();

    // await ethers.provider.getLogs({}).then((data) => {
    //   console.log("getLogs: " + util.inspect(data));
    // });

    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");

    await greeter.deployed();
    expect(await greeter.greet()).to.equal("Hello, world!");

    await greeter.setGreeting("Hola, mundo!");
    // await greeter.connect(myData.user1).setGreeting("Hola, mundo!");
    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
