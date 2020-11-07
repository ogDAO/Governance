const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const util = require('util');

describe("TestSimpleCurve", function() {
  it("TestSimpleCurve - #0", async function() {
    SimpleCurve = await ethers.getContractFactory("SimpleCurve");
    const setup1a = [];
    setup1a.push(SimpleCurve.deploy([], []));
    const [simpleCurve] = await Promise.all(setup1a);
    const owner = await simpleCurve.owner();
    console.log("        owner: " + owner);

    let ownerSigner;
    [ownerSigner] = await ethers.getSigners();
    const expectedOwner = await ownerSigner.getAddress();
    expect(owner).to.equal(expectedOwner);

    async function test(terms, rates, testTerms, expectedRates, decimals) {
      const replacePoints = await simpleCurve.replacePoints(terms, rates);
      // console.log("        replacePoints(" + JSON.stringify(terms) + ", " + JSON.stringify(rates.map((x) => { return ethers.utils.formatUnits(x, decimals); })) + ")");

      const pointsLength = await simpleCurve.pointsLength();
      console.log("        pointsLength: " + pointsLength);

      for (let i = 0; i < pointsLength; i++) {
        const point = await simpleCurve.points(i);
        console.log("        point(" + i + "): term: " + point.term + " => rate: " + point.rate);
      }

      for (let i = 0; i < testTerms.length; i++) {
        const rate = await simpleCurve.getRate(testTerms[i]);
        console.log("        getRate(term: " + testTerms[i] + "): " + rate + ", expected: " + expectedRates[i]);
        expect(rate.toString()).to.equal(expectedRates[i].toString());
      }
    }

    console.log("        --- Test 1 - Increasing rates ---");
    let terms = [2, 5, 10, 100];
    let rates = [20, 50, 100, 1000];
    let testTerms = [1, 2, 3, 5, 7, 10, 100, 101, 10000];
    let expectedRates = [20, 20, 30, 50, 70, 100, 1000, 1000, 1000];
    await test(terms, rates, testTerms, expectedRates, 0);

    console.log("        --- Test 2 - Decreasing rates ---");
    terms = [2, 4, 6, 8, 10];
    rates = [10, 8, 6, 4, 2];
    testTerms = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    expectedRates = [10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 2];
    await test(terms, rates, testTerms, expectedRates, 0);

    console.log("        --- Test 3 - Unixtime and BigNumber ---");
    terms = [BigNumber.from("1604716674"), BigNumber.from("1604736674")];
    rates = [BigNumber.from("1000000000000000000000000"), BigNumber.from("2000000000000000000000000")];
    testTerms = [BigNumber.from("1604716674"), BigNumber.from("1604726674"), BigNumber.from("1604726675"), BigNumber.from("1604726684"), BigNumber.from("1604726774"), BigNumber.from("1604727674")];
    expectedRates = [BigNumber.from("1000000000000000000000000"), BigNumber.from("1500000000000000000000000"), BigNumber.from("1500050000000000000000000"), BigNumber.from("1500500000000000000000000"), BigNumber.from("1505000000000000000000000"), BigNumber.from("1550000000000000000000000")];
    await test(terms, rates, testTerms, expectedRates, 18);

    console.log("        --- Test 4 - Replace Point ---");
    let replaceTerm = 1604746674;
    let replaceRate = BigNumber.from("3000000000000000000000000");
    const replacePoint = await simpleCurve.replacePoint(1, replaceTerm, replaceRate);
    console.log("        replacePoint: " + replacePoint);
    const rate = await simpleCurve.getRate(1604746674);
    console.log("        rate: " + rate);
    expect(rate.toString()).to.equal(replaceRate.toString());

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
