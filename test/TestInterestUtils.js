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
    tests.push({ t: "0d", term: 0, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "100" });
    tests.push({ t: "0d", term: 0, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "100" });
    tests.push({ t: "0d", term: 0, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "100" });
    tests.push({ t: "0d", term: 0, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "100" });
    tests.push({ t: "0d", term: 0, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "100" });
    tests.push({ t: "1/2d", term: SECONDS_PER_DAY / 2, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "100.013057041" });
    tests.push({ t: "1/2d", term: SECONDS_PER_DAY / 2, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "100.013368062" });
    tests.push({ t: "1/2d", term: SECONDS_PER_DAY / 2, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "100.013531114" });
    tests.push({ t: "1/2d", term: SECONDS_PER_DAY / 2, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "100.013642798" });
    tests.push({ t: "1/2d", term: SECONDS_PER_DAY / 2, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "100.013697692" });
    tests.push({ t: "1d", term: SECONDS_PER_DAY, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "100.026115788" });
    tests.push({ t: "1d", term: SECONDS_PER_DAY, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "100.026737910" });
    tests.push({ t: "1d", term: SECONDS_PER_DAY, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "100.027064059" });
    tests.push({ t: "1d", term: SECONDS_PER_DAY, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "100.027287458" });
    tests.push({ t: "1d", term: SECONDS_PER_DAY, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "100.027397260" });
    tests.push({ t: "29d", term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "100.760133420" });
    tests.push({ t: "29d", term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "100.778308959" });
    tests.push({ t: "29d", term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "100.787838769" });
    tests.push({ t: "29d", term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "100.794366807" });
    tests.push({ t: "29d", term: SECONDS_PER_DAY * 29, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "100.797575552" });
    tests.push({ t: "6m", term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "104.880884817" });
    tests.push({ t: "6m", term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "105.000000000" });
    tests.push({ t: "6m", term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "105.062500000" });
    tests.push({ t: "6m", term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "105.105331332" });
    tests.push({ t: "6m", term: SECONDS_PER_YEAR / 2, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "105.126389723" });
    tests.push({ t: "360d", term: SECONDS_PER_DAY * 360, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "109.856475635" });
    tests.push({ t: "360d", term: SECONDS_PER_DAY * 360, ratePercent: "10", amount: "100", p: "360d", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "110.102725424" });
    tests.push({ t: "360d", term: SECONDS_PER_DAY * 360, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "110.232041975" });
    tests.push({ t: "360d", term: SECONDS_PER_DAY * 360, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "110.320705997" });
    tests.push({ t: "360d", term: SECONDS_PER_DAY * 360, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "110.364311310" });
    tests.push({ t: "1y", term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", p: "1y", secondsPerPeriod: SECONDS_PER_YEAR, compoundingResult: "110" });
    tests.push({ t: "1y", term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", p: "6m", secondsPerPeriod: SECONDS_PER_YEAR / 2, compoundingResult: "110.25" });
    tests.push({ t: "1y", term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", p: "3m", secondsPerPeriod: SECONDS_PER_YEAR / 4, compoundingResult: "110.381289063" });
    tests.push({ t: "1y", term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", p: "1m", secondsPerPeriod: SECONDS_PER_YEAR / 12, compoundingResult: "110.471306744" });
    tests.push({ t: "1y", term: SECONDS_PER_YEAR, ratePercent: "10", amount: "100", p: "1d", secondsPerPeriod: SECONDS_PER_DAY, compoundingResult: "110.515578162" });

    const _from = parseInt(new Date().getTime()/1000);
    for (let i = 0; i < tests.length; i++) {
      const test = tests[i];
      const _amount = new BigNumber(test.amount).shiftedBy(18);
      const _to = parseInt(_from) + test.term;
      const _rate = new BigNumber(test.ratePercent).shiftedBy(16);
      const [fv, gasUsed] = await testInterestUtils.futureValue(_amount.toFixed(0), _from, _to, _rate.toFixed(0), test.secondsPerPeriod);
      const diff = new BigNumber(fv.toString()).shiftedBy(-18).minus(new BigNumber(test.compoundingResult));
      console.log("        term: " + test.t + ", period: " + test.p + ", fv: " + new BigNumber(fv.toString()).shiftedBy(-18).toFixed(18) + ", compoundingResult: " + new BigNumber(test.compoundingResult).toFixed(9)  + ", diff: " + diff.toFixed(9) + ", gasUsed: " + gasUsed);
    }

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
