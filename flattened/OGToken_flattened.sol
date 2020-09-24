// File: contracts/Owned.sol

pragma solidity ^0.7.0;

/// @notice Ownership
// SPDX-License-Identifier: GPLv2
contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised, "Already initialised");
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

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
}

// File: contracts/Permissioned.sol

pragma solidity ^0.7.0;



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
    // Don't need ROLE_BURNER at the moment
    // uint public constant ROLE_BURNER = 2;
    mapping(address => mapping(uint => Permission)) public permissions;

    modifier permitted(uint role, uint tokens) {
        Permission storage permission = permissions[msg.sender][role];
        require(permission.active && (permission.maximum == 0 || permission.processed + tokens < permission.maximum), "Not permissioned");
        permission.processed = permission.processed.add(tokens);
        _;
    }

    function initPermissioned(address _owner) internal {
        initOwned(_owner);
        setPermission(_owner, ROLE_MINTER, true, 0);
        // setPermission(_owner, ROLE_BURNER, true, 0);
    }
    function setPermission(address account, uint role, bool active, uint maximum) public onlyOwner {
        uint processed = permissions[account][role].processed;
        permissions[account][role] = Permission({ active: active, maximum: maximum, processed: processed });
    }
    function processed(uint role, uint tokens) internal {
        permissions[msg.sender][role].processed = permissions[msg.sender][role].processed.add(tokens);
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


/// @notice OGTokenInterface = ERC20 + mint + burn
// SPDX-License-Identifier: GPLv2
interface OGTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}

// File: contracts/OGToken.sol

pragma solidity ^0.7.0;

// import "https://github.com/ogDAO/Governance/blob/master/contracts/Permissioned.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGTokenInterface.sol";




// ----------------------------------------------------------------------------
// Optino Governance Token
//
// OGToken = OGTokenInterface (ERC20 + mint + burn)
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: GPLv2
// ----------------------------------------------------------------------------
contract OGToken is OGTokenInterface, Permissioned {
    using SafeMath for uint;

    struct Account {
      uint balance;
      mapping(address => uint) lastDividendPoints;
      mapping(address => uint) owing;
    }

    string _symbol;
    string  _name;
    uint8 _decimals;
    uint _totalSupply;
    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint)) allowed;
    uint public cap;
    bool public freezeCap;
    uint public maxDividendTokens = 20;
    mapping(address => bool) public dividendTokens;
    address[] public dividendTokenIndex;
    uint public constant pointMultiplier = 10e18;
    mapping(address => uint) public totalDividendPoints;
    mapping(address => uint) public unclaimedDividends;

    event CapUpdated(uint256 cap, bool freezeCap);
    event MaxDividendTokensUpdated(uint256 maxDividendTokens);
    event DividendTokensAdded(address dividendToken);
    event LogInfo(string topic, uint number, bytes32 data, string note, address addr);
    event UpdateAccountInfo(address dividendToken, address account, uint owing, uint totalOwing, uint lastDividendPoints, uint totalDividendPoints, uint unclaimedDividends);

    constructor(string memory symbol, string memory name, uint8 decimals, address tokenOwner, uint initialSupply) {
        initPermissioned(msg.sender);
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        accounts[tokenOwner].balance = initialSupply;
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
        return _totalSupply.sub(accounts[address(0)].balance);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        for (uint i = 0; i < dividendTokenIndex.length; i++) {
            address dividendToken = dividendTokenIndex[i];
            updateAccount(dividendToken, msg.sender);
            updateAccount(dividendToken, to);
        }
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        for (uint i = 0; i < dividendTokenIndex.length; i++) {
            address dividendToken = dividendTokenIndex[i];
            updateAccount(dividendToken, msg.sender);
            updateAccount(dividendToken, to);
        }
        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function setCap(uint _cap, bool _freezeCap) external onlyOwner {
        require(!freezeCap, "Cap frozen");
        (cap, freezeCap) = (_cap, _freezeCap);
        emit CapUpdated(cap, freezeCap);
    }
    function setMaxDividendTokens(uint _maxDividendTokens) external onlyOwner {
        require(_maxDividendTokens > dividendTokenIndex.length, "Max must be more than current list length");
        maxDividendTokens = _maxDividendTokens;
        emit MaxDividendTokensUpdated(maxDividendTokens);
    }
    function addDividendToken(address _dividendToken) external onlyOwner {
        require(!dividendTokens[_dividendToken], "Token already in the list");
        dividendTokens[_dividendToken] = true;
        dividendTokenIndex.push(_dividendToken);
        emit DividendTokensAdded(_dividendToken);
    }

    /*
    function disburse(uint amount) {
      totalDividendPoints += (amount * pointsMultiplier / totalSupply);
      totalSupply += amount;
      unclaimedDividends += amount;
    }*/
    function dividendsOwing(address dividendToken, address account) public view returns (uint) {
        uint newDividendPoints = totalDividendPoints[dividendToken] - accounts[account].lastDividendPoints[dividendToken];
        return (accounts[account].balance * newDividendPoints) / pointMultiplier;
    }
    function updateAccount(address dividendToken, address account) internal {
        uint owing = dividendsOwing(dividendToken, account);
        // emit LogInfo("updateAccount: owing", owing, 0x0, "", account);
        if (owing > 0) {
            // emit LogInfo("updateAccount: _unclaimedDividends before", unclaimedDividends[dividendToken], 0x0, "", account);
            unclaimedDividends[dividendToken] = unclaimedDividends[dividendToken].sub(owing);
            // emit LogInfo("updateAccount: _unclaimedDividends after", unclaimedDividends[dividendToken], 0x0, "", account);
            // // emit LogInfo("updateAccount: accounts[account].balance", accounts[account].balance, 0x0, "", account);
            // // accounts[account][dividendToken].balance = accounts[account][dividendToken].balance.add(owing);
            // // emit LogInfo("updateAccount: accounts[account][dividendToken].balance", accounts[account][dividendToken].balance, 0x0, "", account);
            // emit LogInfo("updateAccount: accounts[account].lastDividendPoints[dividendToken] before", accounts[account].lastDividendPoints[dividendToken], 0x0, "", account);
            accounts[account].lastDividendPoints[dividendToken] = totalDividendPoints[dividendToken];
            // emit LogInfo("updateAccount: accounts[account].lastDividendPoints[dividendToken] after", accounts[account].lastDividendPoints[dividendToken], 0x0, "", account);
            accounts[account].owing[dividendToken] = accounts[account].owing[dividendToken].add(owing);
        }
        // emit UpdateAccountInfo(dividendToken, account, owing, accounts[account].owing[dividendToken], accounts[account].lastDividendPoints[dividendToken], totalDividendPoints[dividendToken], unclaimedDividends[dividendToken]);
    }
    function depositDividends(address dividendToken, uint dividends) public {
        // emit LogInfo("depositDividends: dividendToken", 0, 0x0, "", dividendToken);
        // emit LogInfo("depositDividends: dividends", dividends, 0x0, "", address(0));
        // emit LogInfo("depositDividends: pointMultiplier", pointMultiplier, 0x0, "", address(0));
        // emit LogInfo("depositDividends: _totalSupply", _totalSupply, 0x0, "", address(0));
        totalDividendPoints[dividendToken] = totalDividendPoints[dividendToken].add((dividends * pointMultiplier / _totalSupply));
        unclaimedDividends[dividendToken] = unclaimedDividends[dividendToken].add(dividends);
        // emit LogInfo("depositDividends: totalDividendPoints[dividendToken]", totalDividendPoints[dividendToken], 0x0, "", address(0));
        // emit LogInfo("depositDividends: unclaimedDividends[dividendToken]", unclaimedDividends[dividendToken], 0x0, "", address(0));
        ERC20(dividendToken).transferFrom(msg.sender, address(this), dividends);
    }
    function withdrawDividends(address dividendToken) public returns (uint withdrawn) {
        updateAccount(dividendToken, msg.sender);
        withdrawn = 0;
    }
    function mint(address tokenOwner, uint tokens) override external permitted(ROLE_MINTER, tokens) returns (bool success) {
        require(cap == 0 || _totalSupply + tokens <= cap, "Cap exceeded");
        processed(ROLE_MINTER, tokens);
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        for (uint i = 0; i < dividendTokenIndex.length; i++) {
            updateAccount(dividendTokenIndex[i], tokenOwner);
        }
        return true;
    }
    function burn(uint tokens) override external returns (bool success) {
        for (uint i = 0; i < dividendTokenIndex.length; i++) {
            updateAccount(dividendTokenIndex[i], msg.sender);
        }
        // TODO Pay out
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    // function burnFrom(address tokenOwner, uint tokens) override external returns (bool success) {
    //     for (uint i = 0; i < dividendTokenIndex.length; i++) {
    //         updateAccount(dividendTokenIndex[i], tokenOwner);
    //     }
    //     // TODO Pay out
    //     allowed[tokenOwner][msg.sender] = allowed[tokenOwner][msg.sender].sub(tokens);
    //     accounts[tokenOwner].balance = accounts[tokenOwner].balance.sub(tokens);
    //     _totalSupply = _totalSupply.sub(tokens);
    //     emit Transfer(tokenOwner, address(0), tokens);
    //     return true;
    // }
}
