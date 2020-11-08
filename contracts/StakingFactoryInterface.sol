pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./CurveInterface.sol";

/// @notice OGTokenInterface = ERC20 + mint + burn
// SPDX-License-Identifier: GPLv2
interface StakingFactoryInterface {
    function mintOGTokens(address tokenOwner, uint tokens) external;
    function getStakingRewardCurve() external view returns (CurveInterface _stakingRewardCurve);
}
