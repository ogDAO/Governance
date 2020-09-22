pragma solidity ^0.7.0;

import "./ERC20.sol";

/// @notice OFTokenInterface = ERC20 + mint + burn
// SPDX-License-Identifier: GPLv2
interface OFTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}
