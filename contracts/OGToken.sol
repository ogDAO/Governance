pragma solidity ^0.8.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./Permissioned.sol";
import "./OGTokenInterface.sol";


/// @notice Optino Governance Token = ERC20 + mint + burn with optional freezable cap. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGToken is OGTokenInterface, Permissioned {
    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint private _totalSupply;
    mapping(address => uint) private balances;

    mapping(address => mapping(address => uint)) private allowed;
    uint public cap;
    bool public freezeCap;

    event CapUpdated(uint256 cap, bool freezeCap);

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
        return _totalSupply - balances[address(0)];
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
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
        // TODO
        if (permission.maximum == 0) {
            if (cap > 0) {
                tokens = cap - __totalSupply();
            } else {
                tokens = type(uint).max;
            }
        } else {
            tokens = permission.maximum - permission.processed;
            if (cap > 0 && tokens > cap) {
                tokens = cap;
            }
        }
    }
    function mint(address tokenOwner, uint tokens) override external permitted(Roles.MintTokens, tokens) returns (bool success) {
        require(cap == 0 || __totalSupply() + tokens <= cap, "cap exceeded");
        balances[tokenOwner] += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(uint tokens) override external returns (bool success) {
        balances[msg.sender] -= tokens;
        _totalSupply -= tokens;
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    function burnFrom(address tokenOwner, uint tokens) override external permitted(Roles.BurnTokens, tokens) returns (bool success) {
        balances[tokenOwner] -= tokens;
        _totalSupply -= tokens;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
}
