pragma solidity ^0.7.0;

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
library InterestUtils {
    /// @notice Future value of amount with full periods using compound interest and the final partial period using simple interest
    // Re overflows, rate has max 20 sig figs, secondsPerPeriod has 11 sig figs, largest uint has 78 sig figs, so amount can have up to 47 sig figs
    // uint public LARGEST_UINT = uint(int(-1));
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    // 78 significant digits
    // rate max 20 significant digits
    // uint public YEARS_1000 = 1000 * 365 days;
    // secondsPerPeriod max 31536000000 11 significant digits
    // 47 significant digits remaining, so amount must be < 10^40 for safety
    function futureValue(uint amount, uint from, uint to, uint rate, uint secondsPerPeriod) internal pure returns (uint) {
        require(from <= to, "from must be <= to");
        require(rate <= 100 * 10**18, "rate must be <= 10,000%");
        require(secondsPerPeriod <= 1000 * 365 days, "secondsPerPeriod must be <= 1,000 years");
        require(amount <= 10**36, "amount must be <= 10^36");
        uint date = from;

        while (date <= to) {
            if (date + secondsPerPeriod <= to) {
                amount = amount + amount * rate * secondsPerPeriod / 365 days / 10**18;
            } else if (date < to) {
                uint period = (to - date);
                amount = amount + amount * rate * secondsPerPeriod * period / secondsPerPeriod / 365 days / 10**18;
            }
            date = date + secondsPerPeriod;
        }
        return amount;
    }
}
