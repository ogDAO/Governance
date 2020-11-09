pragma solidity ^0.7.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./InterestUtils.sol";

// SPDX-License-Identifier: GPLv2
contract TestInterestUtils {
    function futureValue(uint amount, uint from, uint to, uint rate/*, uint secondsPerPeriod*/) external view returns (uint _futureValue, uint _gasUsed) {
        uint gasStart = gasleft();
        _futureValue = InterestUtils.futureValue(amount, from, to, rate/*, secondsPerPeriod*/);
        _gasUsed = gasStart - gasleft();
        // console.log("        amount: %s, futureValue: %s, gasUsed: %s", amount, _futureValue, _gasUsed);
        // console.log("        from: %s, to: %s, diff: %s", from, to, (to - from));
        // console.log("        rate: %s, secondsPerPeriod: %s", rate, secondsPerPeriod);
    }
}
