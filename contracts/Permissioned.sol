pragma solidity ^0.7.0;

// import "hardhat/console.sol";

import "./SafeMath.sol";

/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned {
    using SafeMath for uint;

    struct Permission {
        address account;
        uint32 role;
        uint8 active;
        uint maximum;
        uint processed;
    }

    uint32 public constant ROLE_SETPERMISSION = 0;
    uint32 public constant ROLE_SETCONFIG = 1;
    uint32 public constant ROLE_MINTTOKENS = 2;
    uint32 public constant ROLE_BURNTOKENS = 3;
    uint32 public constant ROLE_RECOVERTOKENS = 4;
    mapping(bytes32 => Permission) permissions;
    bytes32[] permissionsIndex;

    event PermissionUpdated(address indexed account, uint role, bool active, uint maximum, uint processed);

    modifier permitted(uint32 role, uint tokens) {
        Permission storage permission = permissions[keccak256(abi.encodePacked(msg.sender, role))];
        require(permission.active == uint8(1) && (permission.maximum == 0 || permission.processed.add(tokens) <= permission.maximum), "Not permissioned");
        permission.processed = permission.processed.add(tokens);
        _;
    }

    function initPermissioned(address _owner) internal {
        _setPermission(_owner, ROLE_SETPERMISSION, true, 0);
    }
    function _setPermission(address account, uint32 role, bool active, uint maximum) internal {
        bytes32 key = keccak256(abi.encodePacked(account, role));
        uint processed = permissions[key].processed;
        require(maximum == 0 || maximum >= processed, "Invalid maximum");
        if (permissions[key].account == address(0)) {
            permissions[key] = Permission({ account: account, role: role, active: active ? uint8(1) : uint8(0), maximum: maximum, processed: processed });
            permissionsIndex.push(key);
        } else {
            permissions[key].active = active ? uint8(1) : uint8(0);
            permissions[key].maximum = maximum;
        }
        emit PermissionUpdated(account, role, active, maximum, processed);
    }
    function setPermission(address account, uint32 role, bool active, uint maximum) public permitted(ROLE_SETPERMISSION, 0) {
        _setPermission(account, role, active, maximum);
    }
    function getPermissionByIndex(uint i) public view returns (address account, uint32 role, uint8 active, uint maximum, uint processed) {
        require(i < permissionsIndex.length, "Invalid index");
        Permission memory permission = permissions[permissionsIndex[i]];
        return (permission.account, permission.role, permission.active, permission.maximum, permission.processed);
    }
    function permissionsLength() public view returns (uint) {
        return permissionsIndex.length;
    }
}
