pragma solidity ^0.7.0;

import "./ERC20.sol";

/// @notice OGTokenInterface = ERC20 + mint + burn
// SPDX-License-Identifier: GPLv2
interface StakingFactoryInterface {
    function mintOGTokens(address tokenOwner, uint tokens) external;
}
