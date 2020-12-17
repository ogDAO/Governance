pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./InterestUtils.sol";

// SPDX-License-Identifier: GPLv2
contract TestInterestUtils is InterestUtils {
    function futureValue_(uint amount, uint from, uint to, uint rate) public view returns (uint _futureValue, uint _gasUsed) {
        uint gasStart = gasleft();
        _futureValue = InterestUtils.futureValue(amount, from, to, rate);
        _gasUsed = gasStart - gasleft();
    }
}
