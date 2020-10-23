const { ZERO_ADDRESS, Data } = require('./helpers/common');
const { expect } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

let OGDToken;
let TestToken;
let data;
const verbose = false;

describe("TestOGDToken", function() {
  beforeEach("Setup", async function() {
    OGDToken = await ethers.getContractFactory("OGDToken");
    TestToken = await ethers.getContractFactory("TestToken");
    data = new Data();
    await data.init();

    console.log("        --- Setup 1 - Deploy OGDToken, FEE{0..2} ---");
    const setup1 = [];
    setup1.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, data.owner, new BigNumber("0").shiftedBy(18).toFixed(0)));
    setup1.push(TestToken.deploy("FEE0", "Fee0", 18, data.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    setup1.push(TestToken.deploy("FEE1", "Fee1", 18, data.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    setup1.push(TestToken.deploy("FEE2", "Fee2", 18, data.owner, new BigNumber("10000").shiftedBy(18).toFixed(0)));
    const [ogdToken, fee0Token, fee1Token, fee2Token] = await Promise.all(setup1);
    await data.setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token);
    await data.printTxData("ogdTokenTx", ogdToken.deployTransaction);
    await data.printTxData("fee0TokenTx", fee0Token.deployTransaction);
    await data.printTxData("fee1TokenTx", fee1Token.deployTransaction);
    await data.printTxData("fee2TokenTx", fee2Token.deployTransaction);
    if (verbose) {
      await data.printBalances();
    }

    console.log("        --- Setup 2 - OGDToken.addDividendTokens for ETH and FEE0, OGDToken mint(...) permissioning ---");
    const setup2 = [];
    // setup2.push(data.ogdToken.addDividendToken(ZERO_ADDRESS));
    setup2.push(data.ogdToken.addDividendToken(data.fee0Token.address));
    setup2.push(data.ogdToken.setPermission(data.owner, 1, true, 0));
    const [/*addDividendToken0,*/ addDividendToken1, setPermission1] = await Promise.all(setup2);
    // data.printTxData("addDividendToken0", addDividendToken0);
    data.printTxData("addDividendToken1", addDividendToken1);
    data.printTxData("setPermission1", setPermission1);
    if (verbose) {
      await data.printBalances();
    }

    // console.log("        --- Setup 3 - Mint 10,000 OGD tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
    console.log("        --- Setup 3 - Mint 10,000 OGD tokens for User{1,2}; Owner approve 100 FEE for OGToken to spend ---");
    const setup3 = [];
    const ogdTokens = new BigNumber("10000").shiftedBy(18);
    const approveFee0Tokens = new BigNumber("100").shiftedBy(18);
    const approveFee1Tokens = new BigNumber("1000").shiftedBy(18);
    const approveFee2Tokens = new BigNumber("10000").shiftedBy(18);
    setup3.push(data.ogdToken.mint(data.user1, ogdTokens.toFixed(0)));
    setup3.push(data.ogdToken.mint(data.user2, ogdTokens.toFixed(0)));
    setup3.push(data.ogdToken.mint(data.user3, new BigNumber("0").shiftedBy(18).toFixed(0)));
    setup3.push(data.fee0Token.approve(data.ogdToken.address, approveFee0Tokens.toFixed(0)));
    setup3.push(data.fee1Token.approve(data.ogdToken.address, approveFee1Tokens.toFixed(0)));
    setup3.push(data.fee2Token.approve(data.ogdToken.address, approveFee2Tokens.toFixed(0)));
    const [mint1, mint2, mint3, ownerApproveFee0Tokens, ownerApproveFee1Tokens, ownerApproveFee2Tokens] = await Promise.all(setup3);
    await data.printTxData("mint1", mint1);
    await data.printTxData("mint2", mint2);
    await data.printTxData("mint3", mint3);
    await data.printTxData("ownerApproveFee0Tokens", ownerApproveFee0Tokens);
    await data.printTxData("ownerApproveFee1Tokens", ownerApproveFee1Tokens);
    await data.printTxData("ownerApproveFee2Tokens", ownerApproveFee2Tokens);
    await data.printBalances();

    console.log("        --- Setup Completed ---");
    console.log("");
  });

  // Commenting out to work on a bug
  // describe("TestOGDToken - Standard Workflow #0", function() {
  //   it("Standard Workflow #0", async function() {
  //     console.log("        --- Test 1 - Owner deposits dividends of 100 FEE0 and 10 ETH ---");
  //     const test1 = [];
  //     const depositFee0Tokens = new BigNumber("100").shiftedBy(18);
  //     const depositFeeETH = new BigNumber("10").shiftedBy(18);
  //     test1.push(data.ogdToken.depositDividend(data.fee0Token.address, depositFee0Tokens.toFixed(0)));
  //     test1.push(data.ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH.toFixed(0), { value: depositFeeETH.toFixed(0) }));
  //     const [depositDividendFee0, depositDividendETH0] = await Promise.all(test1);
  //     await data.printTxData("depositDividendFee0", depositDividendFee0);
  //     await data.printTxData("depositDividendETH0", depositDividendETH0);
  //     await data.printBalances();
  //
  //     console.log("        --- Test 2 - User1 dummy transfer to same account (internal stats update) ---");
  //     const test2 = [];
  //     test2.push(data.ogdToken.connect(data.user2Signer).transfer(data.user2, "1"));
  //     const [transfer1] = await Promise.all(test2);
  //     await data.printTxData("transfer1", transfer1);
  //     if (verbose) {
  //       await data.printBalances();
  //     }
  //
  //     console.log("        --- Test 3 - User{1..3} withdraw 33.333333333333333333 FEE0 and 3.333333333333333333 ETH ---");
  //     const test3 = [];
  //     test3.push(data.ogdToken.connect(data.user1Signer).withdrawDividends());
  //     test3.push(data.ogdToken.connect(data.user2Signer).withdrawDividends());
  //     test3.push(data.ogdToken.connect(data.user3Signer).withdrawDividends());
  //     const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(test3);
  //     await data.printTxData("withdrawDividends1", withdrawDividends1);
  //     await data.printTxData("withdrawDividends2", withdrawDividends2);
  //     await data.printTxData("withdrawDividends3", withdrawDividends3);
  //     await data.printBalances();
  //
  //     console.log("        --- Test 4 - Add Fee{1..2} Dividend Token ---");
  //     const test4 = [];
  //     test4.push(data.ogdToken.addDividendToken(data.fee1Token.address));
  //     test4.push(data.ogdToken.addDividendToken(data.fee2Token.address));
  //     const [addDividendToken2, addDividendToken3] = await Promise.all(test4);
  //     await data.printTxData("addDividendToken2", addDividendToken2);
  //     await data.printTxData("addDividendToken3", addDividendToken3);
  //     if (verbose) {
  //       await data.printBalances();
  //     }
  //
  //     console.log("        --- Test 5 - Owner deposits dividends of 1,000 FEE1 and 10,000 FEE2 ---");
  //     const test5 = [];
  //     const depositFee1Tokens = new BigNumber("1000").shiftedBy(18);
  //     const depositFee2Tokens = new BigNumber("10000").shiftedBy(18);
  //     test5.push(data.ogdToken.depositDividend(data.fee1Token.address, depositFee1Tokens.toFixed(0)));
  //     test5.push(data.ogdToken.depositDividend(data.fee2Token.address, depositFee2Tokens.toFixed(0)));
  //     const [depositDividendFee1, depositDividendFee2] = await Promise.all(test5);
  //     await data.printTxData("depositDividendFee1", depositDividendFee1);
  //     await data.printTxData("depositDividendFee2", depositDividendFee2);
  //     if (verbose) {
  //       await data.printBalances();
  //     }
  //
  //     console.log("        --- Test 6 - User{1..3} withdraw 333.333333333333333333 FEE1 and 3333.333333333333333333 FEE2 ---");
  //     const test6 = [];
  //     test6.push(data.ogdToken.connect(data.user1Signer).withdrawDividends());
  //     test6.push(data.ogdToken.connect(data.user2Signer).withdrawDividends());
  //     test6.push(data.ogdToken.connect(data.user3Signer).withdrawDividends());
  //     const [withdrawDividends4, withdrawDividends5, withdrawDividends6] = await Promise.all(test6);
  //     await data.printTxData("withdrawDividends4", withdrawDividends4);
  //     await data.printTxData("withdrawDividends5", withdrawDividends5);
  //     await data.printTxData("withdrawDividends6", withdrawDividends6);
  //     await data.printBalances();
  //
  //     console.log("        --- Test 7 - User2 transfer 1 OGD to User3 ---");
  //     const test7 = [];
  //     test7.push(data.ogdToken.connect(data.user2Signer).transfer(data.user3, new BigNumber("0.123456789123456789").shiftedBy(18).toFixed(0)));
  //     const [transfer2] = await Promise.all(test7);
  //     await data.printTxData("transfer2", transfer2);
  //     await data.printBalances();
  //
  //     const user1Fee1Balance = await data.fee1Token.balanceOf(data.user1);
  //     if (verbose) {
  //       console.log("        user1Fee1Balance: " + user1Fee1Balance);
  //     }
  //     expect(new BigNumber(user1Fee1Balance.toString()).toFixed(0)).to.equal(new BigNumber("333.333333333333333333").shiftedBy(18).toFixed(0));
  //
  //     console.log("        --- Test Completed ---");
  //     console.log("");
  //   });
  // });

  describe.only("TestOGDToken - Standard Workflow #1", function() {
    it("Standard Workflow #1", async function() {
      // console.log("        --- Test 1 - Owner deposits dividends of 100 FEE0 /*and 10 ETH*/ ---");
      console.log("        --- Test 1 - Owner deposits dividends of 100 FEE0 ---");
      const test1 = [];
      const depositFee0Tokens = new BigNumber("100").shiftedBy(18);
      // const depositFeeETH = new BigNumber("10").shiftedBy(18);
      test1.push(data.ogdToken.depositDividend(data.fee0Token.address, depositFee0Tokens.toFixed(0)));
      // test1.push(data.ogdToken.depositDividend(ZERO_ADDRESS, depositFeeETH.toFixed(0), { value: depositFeeETH.toFixed(0) }));
      const [depositDividendFee0/*, depositDividendETH0*/] = await Promise.all(test1);
      await data.printTxData("depositDividendFee0", depositDividendFee0);
      // await data.printTxData("depositDividendETH0", depositDividendETH0);
      await data.printBalances();

      console.log("        --- Test 2 - User2 transfer all tokens to user3 ---");
      const tokensToTransfer = new BigNumber("10000").shiftedBy(18);
      const test2 = [];
      test2.push(data.ogdToken.connect(data.user2Signer).transfer(data.user3, tokensToTransfer.toFixed(0)));
      const [transfer1] = await Promise.all(test2);
      await data.printTxData("transfer1", transfer1);
      await data.printBalances();

      // TEST console.log("        --- Test 3 - User{1..3} withdraw FEE0 ---");
      const test3 = [];
      test3.push(data.ogdToken.connect(data.user1Signer).withdrawDividends());
      test3.push(data.ogdToken.connect(data.user2Signer).withdrawDividends());
      test3.push(data.ogdToken.connect(data.user3Signer).withdrawDividends());
      const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(test3);
      await data.printTxData("withdrawDividends1", withdrawDividends1);
      await data.printTxData("withdrawDividends2", withdrawDividends2);
      await data.printTxData("withdrawDividends3", withdrawDividends3);
      await data.printBalances();
    });
  });

  describe("TestOGDToken - Standard Workflow #2", function() {
    it("Standard Workflow #2", async function() {
      console.log("Standard Workflow #2");
    });
  });
});
