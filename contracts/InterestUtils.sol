pragma solidity ^0.7.0;

import "./SafeMath.sol";

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
library InterestUtils {
    using SafeMath for uint;

    /// @notice Future value of amount with full periods using compound interest and the final partial period using simple interest
    function futureValue(uint amount, uint from, uint to, uint rate, uint secondsPerPeriod) internal pure returns (uint) {
        uint date = from;
        while (date <= to) {
            if (date.add(secondsPerPeriod) <= to) {
                amount = amount.add(amount.mul(rate).mul(secondsPerPeriod).div(365 days * 10**18));
            } else if (date < to) {
                uint period = to.sub(date);
                amount = amount.add(amount.mul(rate.mul(secondsPerPeriod).mul(period)).div(secondsPerPeriod).div(365 days * 10**18));
            }
            date = date.add(secondsPerPeriod);
        }
        return amount;
    }
}
