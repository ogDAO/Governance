pragma solidity ^0.7.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
// import "./SafeMath.sol";
import "./ABDKMathQuad.sol";

// import "hardhat/console.sol";

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
library InterestUtils {
    using ABDKMathQuad for bytes16;

    /// @notice fv = pv * exp(rate% x termInYears)
    function futureValue(uint amount, uint from, uint to, uint rate) internal view returns (uint) {
        require(from <= to, "Invalid date range");
        bytes16 i = ABDKMathQuad.fromUInt(rate).div(ABDKMathQuad.fromUInt(10**18));
        bytes16 t = ABDKMathQuad.fromUInt(to - from).div(ABDKMathQuad.fromUInt(365 days));
        bytes16 fv = ABDKMathQuad.fromUInt(amount).mul(ABDKMathQuad.exp(i.mul(t)));
        return fv.toUInt();
    }
}
