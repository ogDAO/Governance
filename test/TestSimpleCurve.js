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

    let deployerSigner;
    [deployerSigner] = await ethers.getSigners();
    const expectedOwner = await deployerSigner.getAddress();
    expect(owner).to.equal(expectedOwner);

    async function test(terms, rates, testTerms, expectedRates, decimals) {
      const replacePoints = await simpleCurve.replacePoints(terms, rates);
      // console.log("        replacePoints(" + JSON.stringify(terms) + ", " + JSON.stringify(rates.map((x) => { return ethers.utils.formatUnits(x, decimals); })) + ")");

      const pointsLength = await simpleCurve.pointsLength();
      console.log("        pointsLength: " + pointsLength);

      for (let i = 0; i < pointsLength; i++) {
        const point = await simpleCurve.points(i);
        console.log("        point(" + i + "): term: " + point.term + " => rate: " + ethers.utils.formatUnits(point.rate, decimals));
      }

      for (let i = 0; i < testTerms.length; i++) {
        const rate = await simpleCurve.getRate(testTerms[i]);
        console.log("        getRate(term: " + testTerms[i] + "): " + ethers.utils.formatUnits(rate, decimals) + ", expected: " + ethers.utils.formatUnits(expectedRates[i], decimals));
        expect(rate.toString()).to.equal(expectedRates[i].toString());
      }
    }

    console.log("        --- Test 1 - Increasing rates ---");
    let terms1 = [2, 5, 10, 100];
    let rates1 = [20, 50, 100, 1000];
    let testTerms1 = [1, 2, 3, 5, 7, 10, 100, 101, 10000];
    let expectedRates1 = [20, 20, 30, 50, 70, 100, 1000, 1000, 1000];
    await test(terms1, rates1, testTerms1, expectedRates1, 0);

    console.log("        --- Test 2 - Decreasing rates ---");
    let terms2 = [2, 4, 6, 8, 10];
    let rates2 = [10, 8, 6, 4, 2];
    let testTerms2 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    let expectedRates2 = [10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 2];
    await test(terms2, rates2, testTerms2, expectedRates2, 0);

    console.log("        --- Test 3a - Unixtime and BigNumber ---");
    let terms3 = [BigNumber.from("1604716674"), BigNumber.from("1604736674")];
    let rates3 = [BigNumber.from("1000000000000000000000000"), BigNumber.from("2000000000000000000000000")];
    let testTerms3 = [BigNumber.from("1604716674"), BigNumber.from("1604726674"), BigNumber.from("1604726675"), BigNumber.from("1604726684"), BigNumber.from("1604726774"), BigNumber.from("1604727674")];
    let expectedRates3 = [BigNumber.from("1000000000000000000000000"), BigNumber.from("1500000000000000000000000"), BigNumber.from("1500050000000000000000000"), BigNumber.from("1500500000000000000000000"), BigNumber.from("1505000000000000000000000"), BigNumber.from("1550000000000000000000000")];
    await test(terms3, rates3, testTerms3, expectedRates3, 18);

    console.log("        --- Test 3b - Replace Point ---");
    let replaceTerm3 = 1604746674;
    let replaceRate3 = BigNumber.from("3000000000000000000000000");
    const replacePoint3 = await simpleCurve.replacePoint(1, replaceTerm3, replaceRate3);
    const rate3 = await simpleCurve.getRate(1604746674);
    console.log("        Replaced rate3: " + ethers.utils.formatUnits(rate3, 18) + " vs expected " + ethers.utils.formatUnits(replaceRate3, 18));
    expect(rate3.toString()).to.equal(replaceRate3.toString());

    console.log("        --- Test 4 - Linear from (0, 0) ---");
    let terms4 = [0, 365];
    let rates4 = [0, 36500];
    let testTerms4 = [0, 1, 10, 100, 1000];
    let expectedRates4 = [0, 100, 1000, 10000, 36500];
    await test(terms4, rates4, testTerms4, expectedRates4, 0);

    console.log("        --- Test 5 - Variable rates 1 ---");
    let terms5 = [2, 5, 10, 100];
    let rates5 = [20, 500, 100, 1000];
    let testTerms5 = [1, 2, 3, 5, 7, 10, 99, 100, 101, 10000];
    let expectedRates5 = [20, 20, 180, 500, 340, 100, 990, 1000, 1000, 1000];
    await test(terms5, rates5, testTerms5, expectedRates5, 0);

    console.log("        --- Test 6 - Variable rates 2 ---");
    let terms6 = [20, 50, 100, 1000];
    let rates6 = [20, 500, 100, 1000];
    let testTerms6 = [10, 20, 30, 50, 70, 100, 990, 999, 1000, 1010, 100000];
    let expectedRates6 = [20, 20, 180, 500, 340, 100, 990, 999, 1000, 1000, 1000];
    await test(terms6, rates6, testTerms6, expectedRates6, 0);

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
