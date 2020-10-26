pragma solidity ^0.7.0;

import "./Owned.sol";
import "./SafeMath.sol";

/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned is Owned {
    using SafeMath for uint;

    struct Permission {
        bool active;
        uint maximum;
        uint processed;
    }

    uint public constant ROLE_MINTER = 1;
    uint public constant ROLE_DIVIDENDWITHDRAWER = 2;
    // Don't need ROLE_BURNER at the moment
    // uint public constant ROLE_BURNER = 2;
    mapping(address => mapping(uint => Permission)) public permissions;

    event PermissionUpdated(address indexed account, uint role, bool active, uint maximum, uint processed);

    modifier permitted(uint role, uint tokens) {
        Permission storage permission = permissions[msg.sender][role];
        require(permission.active && (permission.maximum == 0 || permission.processed + tokens < permission.maximum), "Not permissioned");
        permission.processed = permission.processed.add(tokens);
        _;
    }

    function initPermissioned(address _owner) internal {
        initOwned(_owner);
        // setPermission(_owner, ROLE_MINTER, true, 0);
        // setPermission(_owner, ROLE_BURNER, true, 0);
    }
    function setPermission(address account, uint role, bool active, uint maximum) public onlyOwner {
        uint processed = permissions[account][role].processed;
        permissions[account][role] = Permission({ active: active, maximum: maximum, processed: processed });
        emit PermissionUpdated(account, role, active, maximum, processed);
    }
    // function processed(uint role, uint tokens) internal {
    //     permissions[msg.sender][role].processed = permissions[msg.sender][role].processed.add(tokens);
    // }
}
