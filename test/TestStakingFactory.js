const { ZERO_ADDRESS, Data } = require('./helpers/common');
const { expect, assert } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

let Staking;
let StakingFactory;
let OGToken;
let TestToken;
let data;
const verbose = false;

describe("TestStakingFactory", function() {
  beforeEach("Setup", async function() {
    Staking = await ethers.getContractFactory("Staking");
    StakingFactory = await ethers.getContractFactory("StakingFactory");
    OGToken = await ethers.getContractFactory("OGToken");
    TestToken = await ethers.getContractFactory("TestToken");
    data = new Data();
    await data.init();

    console.log("        --- Setup 1 - Deploy OGToken, FEE0, StakingFactory ---");
    const setup1a = [];
    setup1a.push(OGToken.deploy("OG", "Optino Governance", 18, data.owner, new BigNumber("0").shiftedBy(18).toFixed(0)));
    setup1a.push(TestToken.deploy("FEE0", "Fee0", 18, data.owner, new BigNumber("100").shiftedBy(18).toFixed(0)));
    const [ogToken, fee0Token] = await Promise.all(setup1a);
    const setup1b = [];
    setup1b.push(StakingFactory.deploy(ogToken.address));
    const [stakingFactory] = await Promise.all(setup1b);
    await data.setStakingFactoryData(ogToken, fee0Token, stakingFactory);

    await data.printTxData("ogTokenTx", ogToken.deployTransaction);
    await data.printTxData("fee0TokenTx", fee0Token.deployTransaction);
    await data.printTxData("stakingFactoryTx", stakingFactory.deployTransaction);
    // await data.printBalances();

    await console.log("        --- Setup 2 - OGToken mint(...) permissioning ---");
    const setup2 = [];
    setup2.push(data.ogToken.setPermission(data.owner, 1, true, 0));
    setup2.push(data.ogToken.setPermission(stakingFactory.address, 1, true, 0));
    const [setPermission1, setPermission2] = await Promise.all(setup2);
    await data.printTxData("setPermission1", setPermission1);
    await data.printTxData("setPermission2", setPermission2);
    await data.printBalances();

    console.log("        --- Setup Completed ---");
    console.log("");
  });

  describe("TestStakingFactory - Workflow #0 - Stake, stake, stake, unstake, unstake", function() {
    it("Workflow #0 - Stake, stake, stake, unstake, unstake", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
      const ogTokens = new BigNumber("10000").shiftedBy(18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user2, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user3, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake = new BigNumber("1000").shiftedBy(18);
      let duration = 6;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.ogToken.address, "OGToken"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      console.log("        --- Test 3 - Stake #2 - StakingFactory.addStakingForToken() ---");
      data.pause("Waiting", duration);
      ogTokensToStake = new BigNumber("1000").shiftedBy(18);
      duration = 3;
      const test3 = [];
      test3.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test3.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test3.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.ogToken.address, "OGToken"));
      const [addStake4, addStake5, addStake6] = await Promise.all(test3);
      await data.printTxData("addStake4", addStake4);
      await data.printTxData("addStake5", addStake5);
      await data.printTxData("addStake6", addStake6);
      await data.printBalances();

      console.log("        --- Test 4 - Stake #3 - Staking.stake() ---");
      ogTokensToStake = new BigNumber("1000").shiftedBy(18);
      duration = 3;

      const test4a = [];
      test4a.push(data.ogToken.connect(data.user1Signer).approve(stakings[0].address, ogTokensToStake.toFixed(0)));
      test4a.push(data.ogToken.connect(data.user2Signer).approve(stakings[0].address, ogTokensToStake.toFixed(0)));
      test4a.push(data.ogToken.connect(data.user3Signer).approve(stakings[1].address, ogTokensToStake.toFixed(0)));
      const [approve4, approve5, approve6] = await Promise.all(test4a);
      await data.printTxData("approve4", approve4);
      await data.printTxData("approve5", approve5);
      await data.printTxData("approve6", approve6);
      const test4b = [];
      test4b.push(stakings[0].connect(data.user1Signer).stake(ogTokensToStake.toFixed(0), duration));
      test4b.push(stakings[0].connect(data.user2Signer).stake(ogTokensToStake.toFixed(0), duration));
      test4b.push(stakings[1].connect(data.user3Signer).stake(ogTokensToStake.toFixed(0), duration));
      const [addStake7, addStake8, addStake9] = await Promise.all(test4b);
      await data.printTxData("addStake7", addStake7);
      await data.printTxData("addStake8", addStake8);
      await data.printTxData("addStake9", addStake9);
      await data.printBalances();

      console.log("        --- Test 5 - Unstake #1 - unstake(some) ---");
      data.pause("Waiting", duration);
      let ogTokensToUnstake = new BigNumber("2000").shiftedBy(18);
      const test5 = [];
      test5.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test5.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test5.push(stakings[1].connect(data.user3Signer).unstake(ogTokensToUnstake.toFixed(0)));
      const [unstake1, unstake2, unstake3] = await Promise.all(test5);
      await data.printTxData("unstake1", unstake1);
      await data.printTxData("unstake2", unstake2);
      await data.printTxData("unstake3", unstake3);
      await data.printBalances();

      console.log("        --- Test 6 - Unstake #2 - unstake(remaining) ---");
      ogTokensToUnstake = new BigNumber("1000").shiftedBy(18);
      const test6 = [];
      test6.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test6.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test6.push(stakings[1].connect(data.user3Signer).unstake(ogTokensToUnstake.toFixed(0)));
      const [unstake4, unstake5, unstake6] = await Promise.all(test6);
      await data.printTxData("unstake4", unstake4);
      await data.printTxData("unstake5", unstake5);
      await data.printTxData("unstake6", unstake6);
      await data.printBalances();
    });
  });

  describe("TestStakingFactory - Workflow #1 - Stake And Check weightedEnd", function() {
    it("Workflow #1 - Stake And Check weightedEnd", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
      const ogTokens = new BigNumber("10000").shiftedBy(18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user2, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user3, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake1 = new BigNumber("1000").shiftedBy(18);
      let ogTokensToStake2 = new BigNumber("2000").shiftedBy(18);
      let ogTokensToStake3 = new BigNumber("3000").shiftedBy(18);
      let duration1 = 1000;
      let duration2 = 10000;
      let duration3 = 100000;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake1.toFixed(0), duration1, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake2.toFixed(0), duration2, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3.toFixed(0), duration3, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      // await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      const expectedDuration = ogTokensToStake1.multipliedBy(duration1).plus(ogTokensToStake2.multipliedBy(duration2)).plus(ogTokensToStake3.multipliedBy(duration3)).dividedBy(ogTokensToStake1.plus(ogTokensToStake2).plus(ogTokensToStake3));
      const expectedWeightedEnd = expectedDuration.plus(new Date()/1000);
      console.log("        expectedWeightedEnd: " + expectedWeightedEnd);
      const weightedEnd = await stakings[0].weightedEnd();
      console.log("        weightedEnd        : " + weightedEnd);
      expect(parseFloat(weightedEnd.toString())).to.be.closeTo(parseFloat(expectedWeightedEnd.toString()), 150, "weightedEnd seems off");
    });
  });

  describe("TestStakingFactory - Workflow #2 - Stake with expected exception", function() {
    it("Workflow #2 - Stake with expected exception", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for User{1..3}; Owner approve 100 FEE for OGToken to spend ---");
      const ogTokens = new BigNumber("10000").shiftedBy(18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user2, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user3, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake1 = new BigNumber("1000").shiftedBy(18);
      let ogTokensToStake2 = new BigNumber("2000").shiftedBy(18);
      let ogTokensToStake3 = ogTokens.plus(new BigNumber("1").shiftedBy(18));
      let duration1 = 1000;
      let duration2 = 10000;
      let duration3 = 100000;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake1.toFixed(0), duration1, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake2.toFixed(0), duration2, data.fee0Token.address, "FEE0Token"));
      // test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3.toFixed(0), duration3, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2/*, addStake3*/] = await Promise.all(test2);
      await data.expectException("Insufficient approved OG tokens to stake with", "Sub underflow", data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3.toFixed(0), duration3, data.fee0Token.address, "FEE0Token"));

      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      // await data.printTxData("addStake3", addStake3);
      await data.printBalances();
    });
  });

  describe("TestStakingFactory - Workflow #3 - Stake, slash and unstake", function() {
    it("Workflow #3 - Stake, slash and unstake", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for User{1..3}; User{1..3} approve 10,000 FEE for StakingFactory to spend ---");
      const ogTokens = new BigNumber("10000").shiftedBy(18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user2, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user3, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - User{1..3} -> StakingFactory.addStakingForToken(1,000, duration) ---");
      let ogTokensToStake = new BigNumber("1000").shiftedBy(18);
      let duration = 3;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      console.log("        --- Test 3 - owner -> StakingFactory.slash(staking, 30%) ---");
      let slashingFactor = new BigNumber("3").shiftedBy(17); // 30%
      const test3 = [];
      test3.push(data.stakingFactory.slash(stakings[0].address, slashingFactor.toFixed(0)));
      const [slash1] = await Promise.all(test3);
      await data.printTxData("slash1", slash1);
      await data.printBalances();

      console.log("        --- Test 4 - User{1..3} -> unstake(1,000) ---");
      ogTokensToUnstake = new BigNumber("1000").shiftedBy(18);
      const test4 = [];
      test4.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test4.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test4.push(stakings[0].connect(data.user3Signer).unstake(ogTokensToUnstake.toFixed(0)));
      const [unstake1, unstake2, unstake3] = await Promise.all(test4);
      await data.printTxData("unstake1", unstake1);
      await data.printTxData("unstake2", unstake2);
      await data.printTxData("unstake3", unstake3);
      await data.printBalances();
    });
  });

  describe.only("TestStakingFactory - Workflow #3 - Stake, and test transfers", function() {
    it("Workflow #3 - Stake, slash and unstake", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for User{1..3}; User{1..3} approve 10,000 FEE for StakingFactory to spend ---");
      const ogTokens = new BigNumber("10000").shiftedBy(18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user2, ogTokens.toFixed(0)));
      test1.push(data.ogToken.mint(data.user3, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens.toFixed(0)));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - User{1..3} -> StakingFactory.addStakingForToken(1,000, duration) ---");
      let ogTokensToStake = new BigNumber("1000").shiftedBy(18);
      let duration = 2;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      // test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      // test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake.toFixed(0), duration, data.fee0Token.address, "FEE0Token"));
      const [addStake1/*, addStake2, addStake3*/] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      // await data.printTxData("addStake2", addStake2);
      // await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      // console.log("        --- Test 3 - OGS transferX locked during staking period ---");
      // const test3a = [];
      // test3a.push(stakings[0].connect(data.user2Signer).approve(data.user3, new BigNumber("1000").shiftedBy(18).toFixed(0)));
      // const [approve4] = await Promise.all(test3a);
      // await data.printTxData("approve4", approve4);
      // await data.expectException("OGS transfer locked", "Stake period not ended", stakings[0].connect(data.user1Signer).transfer(data.user4, new BigNumber("1.111111111111111111").shiftedBy(18).toFixed(0)));
      // await data.expectException("OGS transferFrom locked", "Stake period not ended", stakings[0].connect(data.user3Signer).transferFrom(data.user2, data.user4, new BigNumber("2.222222222222222222").shiftedBy(18).toFixed(0)));

      // console.log("        --- Test 4 - OGS transferX unlocked after staking period ---");
      // data.pause("Waiting", duration + 1);
      // const test4 = [];
      //
      // test4.push(stakings[0].connect(data.user1Signer).transfer(data.user4, ogTokensToStake.dividedBy(2).toFixed(0)));
      // // test4.push(stakings[0].connect(data.user1Signer).transfer(data.user4, new BigNumber("1.111111111111111111").shiftedBy(18).toFixed(0)));
      // // test4.push(stakings[0].connect(data.user3Signer).transferFrom(data.user2, data.user4, new BigNumber("2.222222222222222222").shiftedBy(18).toFixed(0)));
      // const [transfer1/*, transferFrom1*/] = await Promise.all(test4);
      // await data.printTxData("transfer1", transfer1);
      // // await data.printTxData("transferFrom1", transferFrom1);
      // await data.printBalances();

      // const user4Staking0Balance = await stakings[0].balanceOf(data.user4);
      // console.log("        user4Staking0Balance: " + new BigNumber(user4Staking0Balance.toString()).shiftedBy(-18));
      // expect(new BigNumber(user4Staking0Balance.toString()).toFixed(0)).to.equal(new BigNumber("3.333333333333333333").shiftedBy(18).toFixed(0));

      // console.log("        --- Test 5 - owner -> StakingFactory.slash(staking, 10%) ---");
      // let slashingFactor = new BigNumber("1").shiftedBy(17); // 30%
      // const test5 = [];
      // test5.push(data.stakingFactory.slash(stakings[0].address, slashingFactor.toFixed(0)));
      // const [slash1] = await Promise.all(test5);
      // await data.printTxData("slash1", slash1);
      // await data.printBalances();

      console.log("        --- Test 6 - User{1..4} -> unstake(1,000) ---");
      data.pause("Waiting", duration + 1);
      ogTokensToUnstake = new BigNumber("1000").shiftedBy(18);
      // const user1Staking0Balance = await stakings[0].balanceOf(data.user1);
      // const user2Staking0Balance = await stakings[0].balanceOf(data.user2);
      // const user3Staking0Balance = await stakings[0].balanceOf(data.user3);
      // const user4Staking0Balance = await stakings[0].balanceOf(data.user4);
      const test6 = [];
      // test6.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake.toFixed(0)));
      test6.push(stakings[0].connect(data.user1Signer).unstake(await stakings[0].balanceOf(data.user1)));
      // test6.push(stakings[0].connect(data.user2Signer).unstake(await stakings[0].balanceOf(data.user2)));
      // test6.push(stakings[0].connect(data.user3Signer).unstake(await stakings[0].balanceOf(data.user3)));
      // test6.push(stakings[0].connect(data.user4Signer).unstake(await stakings[0].balanceOf(data.user4)));
      const [unstake1/*, unstake2, unstake3, unstake4*/] = await Promise.all(test6);
      await data.printTxData("unstake1", unstake1);
      // await data.printTxData("unstake2", unstake2);
      // await data.printTxData("unstake3", unstake3);
      // await data.printTxData("unstake4", unstake4);
      await data.printBalances();
    });
  });
});
