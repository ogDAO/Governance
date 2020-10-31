pragma solidity ^0.7.0;

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
library InterestUtils {
    uint constant ONE = 10 ** 18;

    /// @notice Future value of amount with full periods using compound interest and the final partial period using simple interest
    function futureValue(uint amount, uint from, uint to, uint rate, uint secondsPerPeriod) internal pure returns (uint) {
        require(from <= to, "from must be <= to");
        require(rate <= 100 * 10**18, "rate must be <= 10,000%");
        require(secondsPerPeriod <= 1000 * 365 days, "secondsPerPeriod must be <= 1,000 years");
        uint date = from;

        while (date <= to) {
            if (date + secondsPerPeriod <= to) {
                amount = amount + amount * rate * secondsPerPeriod / 365 days / ONE;
            } else if (date < to) {
                uint period = (to - date);
                amount = amount + amount * rate * secondsPerPeriod * period / secondsPerPeriod / 365 days / ONE;
            }
            date = date + secondsPerPeriod;
        }
        return amount;
    }
}
