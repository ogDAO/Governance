pragma solidity ^0.7.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./ABDKMathQuad.sol";

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
contract InterestUtils {
    using ABDKMathQuad for bytes16;
    bytes16 immutable ten_18 = ABDKMathQuad.fromUInt(10**18);
    bytes16 immutable days_365 = ABDKMathQuad.fromUInt(365 days);

    /// @notice futureValue = presentValue x exp(rate% x termInYears)
    function futureValue(uint presentValue, uint from, uint to, uint rate) internal view returns (uint) {
        require(from <= to, "Invalid date range");
        bytes16 i = ABDKMathQuad.fromUInt(rate).div(ten_18);
        bytes16 t = ABDKMathQuad.fromUInt(to - from).div(days_365);
        // bytes16 i = ABDKMathQuad.fromUInt(rate).div(ABDKMathQuad.fromUInt(10**18));
        // bytes16 t = ABDKMathQuad.fromUInt(to - from).div(ABDKMathQuad.fromUInt(365 days));
        bytes16 fv = ABDKMathQuad.fromUInt(presentValue).mul(ABDKMathQuad.exp(i.mul(t)));
        return fv.toUInt();
    }
}
