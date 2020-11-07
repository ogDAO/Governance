pragma solidity ^0.7.0;

// SPDX-License-Identifier: GPLv2
interface CurveInterface {
    function getRate(uint term) external view returns (uint rate);
}
