// File: contracts/SafeMath.sol

pragma solidity ^0.7.0;

/// @notice Safe maths
// SPDX-License-Identifier: GPLv2
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Add overflow");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Sub underflow");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Mul overflow");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Divide by 0");
        c = a / b;
    }
    function max(uint a, uint b) internal pure returns (uint c) {
        c = a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint c) {
        c = a <= b ? a : b;
    }
}

// File: contracts/Permissioned.sol

pragma solidity ^0.7.0;

// import "hardhat/console.sol";


/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned {
    using SafeMath for uint;

    enum Roles {
        SetPermission,
        SetConfig,
        MintTokens,
        BurnTokens,
        RecoverTokens
    }

    struct Permission {
        address account;
        Roles role;
        uint8 active;
        uint maximum;
        uint processed;
    }

    mapping(bytes32 => Permission) permissions;
    bytes32[] permissionsIndex;

    event PermissionUpdated(address indexed account, Roles role, bool active, uint maximum, uint processed);

    modifier permitted(Roles role, uint tokens) {
        Permission storage permission = permissions[keccak256(abi.encodePacked(msg.sender, role))];
        require(permission.active == uint8(1) && (permission.maximum == 0 || permission.processed.add(tokens) <= permission.maximum), "Not permissioned");
        permission.processed = permission.processed.add(tokens);
        _;
    }

    function initPermissioned(address _owner) internal {
        _setPermission(_owner, Roles.SetPermission, true, 0);
    }
    function _setPermission(address account, Roles role, bool active, uint maximum) internal {
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
    function setPermission(address account, Roles role, bool active, uint maximum) public permitted(Roles.SetPermission, 0) {
        _setPermission(account, role, active, maximum);
    }
    function getPermissionByIndex(uint i) public view returns (address account, Roles role, uint8 active, uint maximum, uint processed) {
        require(i < permissionsIndex.length, "Invalid index");
        Permission memory permission = permissions[permissionsIndex[i]];
        return (permission.account, permission.role, permission.active, permission.maximum, permission.processed);
    }
    function permissionsLength() public view returns (uint) {
        return permissionsIndex.length;
    }
}

// File: contracts/ERC20.sol

pragma solidity ^0.7.0;

/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
// SPDX-License-Identifier: GPLv2
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/OGTokenInterface.sol

pragma solidity ^0.7.0;


/// @notice OGTokenInterface = ERC20 + mint + burn with optional freezable cap. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGTokenInterface is ERC20 {
    function availableToMint() external view returns (uint tokens);
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}

// File: contracts/OGToken.sol

pragma solidity ^0.7.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix




/// @notice Optino Governance Token = ERC20 + mint + burn with optional freezable cap. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGToken is OGTokenInterface, Permissioned {
    using SafeMath for uint;

    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint private _totalSupply;
    mapping(address => uint) private balances;

    mapping(address => mapping(address => uint)) private allowed;
    uint public cap;
    bool public freezeCap;


    event CapUpdated(uint256 cap, bool freezeCap);
    event LogInfo(string topic, uint number, bytes32 data, string note, address addr);

    constructor(string memory __symbol, string memory __name, uint8 __decimals, address tokenOwner, uint initialSupply) {
        initPermissioned(msg.sender);
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
        balances[tokenOwner] = initialSupply;
        _totalSupply = initialSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }
    function symbol() override external view returns (string memory) {
        return _symbol;
    }
    function name() override external view returns (string memory) {
        return _name;
    }
    function decimals() override external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() override external view returns (uint) {
        return __totalSupply();
    }
    function __totalSupply() internal view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function setCap(uint _cap, bool _freezeCap) external permitted(Roles.SetConfig, 0) {
        require(!freezeCap, "Cap frozen");
        require(_cap >= __totalSupply(), "cap must be >= totalSupply");
        (cap, freezeCap) = (_cap, _freezeCap);
        emit CapUpdated(cap, freezeCap);
    }

    function availableToMint() override external view returns (uint tokens) {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, Roles.MintTokens));
        Permission memory permission = permissions[key];
        if (permission.maximum == 0) {
            if (cap > 0) {
                tokens = cap.sub(__totalSupply());
            } else {
                tokens = uint(-1);
            }
        } else {
            tokens = permission.maximum.sub(permission.processed);
            if (cap > 0 && tokens > cap) {
                tokens = cap;
            }
        }
    }
    function mint(address tokenOwner, uint tokens) override external permitted(Roles.MintTokens, tokens) returns (bool success) {
        require(cap == 0 || __totalSupply().add(tokens) <= cap, "cap exceeded");
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(uint tokens) override external returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    function burnFrom(address tokenOwner, uint tokens) override external permitted(Roles.BurnTokens, tokens) returns (bool success) {
        balances[tokenOwner] = balances[tokenOwner].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
}
