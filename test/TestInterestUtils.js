const { expect, assert } = require("chai");
const BigNumber = require('bignumber.js');
const util = require('util');

let InterestUtils;

describe("TestInterestUtils", function() {
  it("TestInterestUtils - #0", async function() {
    const SECONDS_PER_DAY = 60 * 60 * 24;
    const SECONDS_PER_YEAR = 365 * SECONDS_PER_DAY;

    TestInterestUtils = await ethers.getContractFactory("TestInterestUtils");

    console.log("        --- Test 1 - Deploy TestInterestUtils ---");
    const setup1a = [];
    setup1a.push(TestInterestUtils.deploy());
    const [testInterestUtils] = await Promise.all(setup1a);

    const tests = [];
    tests.push({ term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR, expectedResult: "110" });
    tests.push({ term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 2, expectedResult: "110.25" });
    tests.push({ term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 4, expectedResult: "110.381289063" });
    tests.push({ term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 12, expectedResult: "110.471306744" });
    tests.push({ term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_DAY, expectedResult: "110.515578162" });
    tests.push({ term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR, expectedResult: "104.880884817" });
    tests.push({ term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 2, expectedResult: "105.000000000" });
    tests.push({ term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 4, expectedResult: "105.062500000" });
    tests.push({ term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 12, expectedResult: "105.105331332" });
    tests.push({ term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_DAY, expectedResult: "105.126389723" });
    tests.push({ term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR, expectedResult: "100.760133420" });
    tests.push({ term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 2, expectedResult: "100.778308959" });
    tests.push({ term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 4, expectedResult: "100.787838769" });
    tests.push({ term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_YEAR / 12, expectedResult: "100.794366807" });
    tests.push({ term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", secondsPerPeriod: SECONDS_PER_DAY, expectedResult: "100.797575552" });

    const _from = parseInt(new Date().getTime()/1000);
    for (let i = 0; i < tests.length; i++) {
      const test = tests[i];
      const _amount = new BigNumber(test.amount).shiftedBy(18);
      const _to = parseInt(_from) + test.term;
      const _rate = new BigNumber(test.ratePercent).shiftedBy(16);
      const [fv1, gasUsed1] = await testInterestUtils.futureValue(_amount.toFixed(0), _from, _to, _rate.toFixed(0), test.secondsPerPeriod);
      const diff = new BigNumber(fv1.toString()).shiftedBy(-18).minus(new BigNumber(test.expectedResult));
      console.log("        fv1: " + new BigNumber(fv1.toString()).shiftedBy(-18) + ", gasUsed1: " + gasUsed1 + ", expected: " + test.expectedResult + ", diff: " + diff.toFixed(9));
    }

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
