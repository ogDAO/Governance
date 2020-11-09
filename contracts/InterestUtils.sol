pragma solidity ^0.7.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
// import "./SafeMath.sol";
import "./ABDKMath64x64.sol";

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
library InterestUtils {
    using ABDKMath64x64 for int128;
    // using SafeMath for uint;

    // /// @notice Future value of amount with full periods using compound interest and the final partial period using simple interest
    // function futureValue(uint amount, uint from, uint to, uint rate, uint secondsPerPeriod) internal pure returns (uint) {
    //     while (from <= to) {
    //         if (from.add(secondsPerPeriod) <= to) {
    //             amount = amount.add(amount.mul(rate).mul(secondsPerPeriod).div(365 days * 10**18));
    //         } else if (from < to) {
    //             uint period = to.sub(from);
    //             amount = amount.add(amount.mul(rate.mul(secondsPerPeriod).mul(period)).div(secondsPerPeriod).div(365 days * 10**18));
    //         }
    //         from = from.add(secondsPerPeriod);
    //     }
    //     return amount;
    // }

    /// @notice fv = pv * exp(rate% x termInYears)
    function futureValue(uint amount, uint from, uint to, uint rate) internal pure returns (uint) {
        require(from <= to, "Invalid date range");
        int128 i = ABDKMath64x64.fromUInt(rate).div(ABDKMath64x64.fromUInt(10**18));
        int128 t = ABDKMath64x64.fromUInt(to - from).div(ABDKMath64x64.fromUInt(365 days));
        int128 fv = ABDKMath64x64.fromUInt(amount).mul(ABDKMath64x64.exp(i.mul(t)));
        return fv.toUInt();
    }
}
