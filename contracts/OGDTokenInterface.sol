pragma solidity ^0.7.0;

import "./ERC20.sol";

/// @notice OGDTokenInterface = ERC20 + mint + burn (+ dividend payment)
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens, address payDividendsTo) external returns (bool success);
    function withdrawDividendsFor(address account, address destination) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}
