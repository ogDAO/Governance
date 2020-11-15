pragma solidity ^0.7.0;

// import "hardhat/console.sol";

import "./SafeMath.sol";
import "./Owned.sol";

/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned is Owned {
    using SafeMath for uint;

    struct Permission {
        address account;
        uint32 role;
        uint8 active;
        uint maximum;
        uint processed;
    }

    uint32 public constant ROLE_MINTER = 1;
    uint32 public constant ROLE_DIVIDENDWITHDRAWER = 2;
    // Don't need ROLE_BURNER at the moment
    // uint public constant ROLE_BURNER = 2;
    mapping(bytes32 => Permission) public permissions;
    bytes32[] permissionsIndex;

    event PermissionUpdated(address indexed account, uint role, bool active, uint maximum, uint processed);

    modifier permitted(uint32 role, uint tokens) {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, role));
        Permission storage permission = permissions[key];
        require(permission.active == uint8(1) && (permission.maximum == 0 || permission.processed.add(tokens) <= permission.maximum), "Not permissioned");
        permission.processed = permission.processed.add(tokens);
        _;
    }

    function initPermissioned(address _owner) internal {
        initOwned(_owner);
        // setPermission(_owner, ROLE_MINTER, true, 0);
        // setPermission(_owner, ROLE_BURNER, true, 0);
    }
    function setPermission(address account, uint32 role, bool active, uint maximum) public onlyOwner {
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

    function getPermissionByIndex(uint i) public view returns (address account, uint32 role, uint8 active, uint maximum, uint processed) {
        require(i < permissionsIndex.length, "Invalid index");
        Permission memory permission = permissions[permissionsIndex[i]];
        return (permission.account, permission.role, permission.active, permission.maximum, permission.processed);
    }

    function permissionsLength() public view returns (uint) {
        return permissionsIndex.length;
    }

    // function available(uint role) public view returns (uint tokens) {
    //     Permission memory permission = permissions[msg.sender][role];
    //     tokens = permission.maximum == 0 ? uint(-1) : permission.maximum.sub(permission.processed);
    //     console.log("        > %s -> Permissioned.available: %s, processed: %s", msg.sender, tokens, permission.processed);
    // }
}
