pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPLv2
interface CurveInterface {
    function getRate(uint term) external view returns (uint rate);
}
