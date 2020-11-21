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

// File: contracts/OGDTokenInterface.sol

pragma solidity ^0.7.0;


/// @notice OGDTokenInterface = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}

// File: contracts/DividendTokens.sol

pragma solidity ^0.7.0;

/// @notice DividendTokens to map [token] => [enabled]
// SPDX-License-Identifier: GPLv2
library DividendTokens {
    struct DividendToken {
        uint timestamp;
        uint index;
        address token;
        bool enabled;
    }
    struct Data {
        bool initialised;
        mapping(address => DividendToken) entries;
        address[] index;
    }

    event DividendTokenAdded(address indexed token, bool enabled);
    event DividendTokenRemoved(address indexed token);
    event DividendTokenUpdated(address indexed token, bool enabled);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function add(Data storage self, address token, bool enabled) internal {
        require(self.entries[token].timestamp == 0, "DividendToken.add: Cannot add duplicate");
        self.index.push(token);
        self.entries[token] = DividendToken(block.timestamp, self.index.length - 1, token, enabled);
        emit DividendTokenAdded(token, enabled);
    }
    function remove(Data storage self, address token) internal {
        require(self.entries[token].timestamp > 0, "DividendToken.update: Address not registered");
        uint removeIndex = self.entries[token].index;
        emit DividendTokenRemoved(token);
        uint lastIndex = self.index.length - 1;
        address lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[token];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function update(Data storage self, address token, bool enabled) internal {
        DividendToken storage entry = self.entries[token];
        require(entry.timestamp > 0, "DividendToken.update: Address not registered");
        entry.timestamp = block.timestamp;
        entry.enabled = enabled;
        emit DividendTokenUpdated(token, enabled);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}

// File: contracts/OGDToken.sol

pragma solidity ^0.7.0;
// pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix





/// @notice Optino Governance Dividend Token = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGDToken is OGDTokenInterface, Permissioned {
    using SafeMath for uint;
    using DividendTokens for DividendTokens.Data;
    using DividendTokens for DividendTokens.DividendToken;

    struct Account {
      uint balance;
      mapping(address => uint) lastDividendPoints;
      mapping(address => uint) owing;
    }

    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint private _totalSupply;
    mapping(address => Account) private accounts;
    mapping(address => mapping(address => uint)) private allowed;

    DividendTokens.Data private dividendTokens;

    uint private constant POINT_MULTIPLIER = 10e27;
    mapping(address => uint) public totalDividendPoints;
    mapping(address => uint) public unclaimedDividends;

    event UpdateAccountInfo(address dividendToken, address account, uint owing, uint totalOwing, uint lastDividendPoints, uint totalDividendPoints, uint unclaimedDividends);
    event DividendDeposited(address indexed token, uint tokens);
    event DividendWithdrawn(address indexed account, address indexed destination, address indexed token, uint tokens);

    // Duplicated from the library for ABI generation
    event DividendTokenAdded(address indexed token, bool enabled);
    event DividendTokenRemoved(address indexed token);
    event DividendTokenUpdated(address indexed token, bool enabled);

    constructor(string memory __symbol, string memory __name, uint8 __decimals, address tokenOwner, uint initialSupply) {
        initPermissioned(msg.sender);
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
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
        updateAccount(msg.sender);
        updateAccount(to);
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
        updateAccount(from);
        updateAccount(to);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[from].balance = accounts[from].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function addDividendToken(address _dividendToken) external permitted(ROLE_SETCONFIG, 0) {
        if (!dividendTokens.initialised) {
            dividendTokens.init();
        }
        dividendTokens.add(_dividendToken, true);
    }
    function updateDividendToken(address token, bool enabled) public permitted(ROLE_SETCONFIG, 0) {
        require(dividendTokens.initialised);
        dividendTokens.update(token, enabled);
    }
    function removeDividendToken(address token) public permitted(ROLE_SETCONFIG, 0) {
        require(dividendTokens.initialised);
        dividendTokens.remove(token);
    }
    function getDividendTokenByIndex(uint i) public view returns (address, bool) {
        require(i < dividendTokens.length(), "Invalid dividend token index");
        DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
        return (dividendToken.token, dividendToken.enabled);
    }
    function dividendTokensLength() public view returns (uint) {
        return dividendTokens.length();
    }

    /// @notice Dividends owning since the last updateAccount(...) + new dividends owing since the last updateAccount(...)
    function dividendsOwing(address account) public view returns (address[] memory tokenList, uint[] memory owingList, uint[] memory newOwingList) {
        tokenList = new address[](dividendTokens.index.length);
        owingList = new uint[](dividendTokens.index.length);
        newOwingList = new uint[](dividendTokens.index.length);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            tokenList[i] = dividendToken.token;
            owingList[i] = accounts[account].owing[dividendToken.token];
            newOwingList[i] = newDividendsOwing(dividendToken.token, account);
        }
    }
    /// @notice New dividends owing since the last updateAccount(...)
    function newDividendsOwing(address dividendToken, address account) internal view returns (uint) {
        uint newDividendPoints = totalDividendPoints[dividendToken].sub(accounts[account].lastDividendPoints[dividendToken]);
        return accounts[account].balance.mul(newDividendPoints).div(POINT_MULTIPLIER);
    }
    function updateAccount(address account) internal {
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint newOwing = newDividendsOwing(dividendToken.token, account);
                if (newOwing > 0) {
                    unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing);
                    accounts[account].owing[dividendToken.token] = accounts[account].owing[dividendToken.token].add(newOwing);
                }
                accounts[account].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
            }
        }
    }
    // function updateAccounts(address account1, address account2) internal {
    //     for (uint i = 0; i < dividendTokens.index.length; i++) {
    //         DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
    //         if (dividendToken.enabled) {
    //             uint newOwing1 = newDividendsOwing(dividendToken.token, account1);
    //             if (newOwing1 > 0) {
    //                 unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing1);
    //                 accounts[account1].owing[dividendToken.token] = accounts[account1].owing[dividendToken.token].add(newOwing1);
    //             }
    //             accounts[account1].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
    //             if (account1 != account2) {
    //                 uint newOwing2 = newDividendsOwing(dividendToken.token, account2);
    //                 if (newOwing2 > 0) {
    //                     unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing2);
    //                     accounts[account2].owing[dividendToken.token] = accounts[account2].owing[dividendToken.token].add(newOwing2);
    //                 }
    //                 accounts[account2].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
    //             }
    //         }
    //     }
    // }

    /// @notice Deposit enabled dividend token
    function depositDividend(address token, uint tokens) public payable {
        DividendTokens.DividendToken memory _dividendToken = dividendTokens.entries[token];
        require(_totalSupply > accounts[address(0)].balance, "totalSupply is 0");
        require(_dividendToken.enabled, "Dividend token is not enabled");
        totalDividendPoints[token] = totalDividendPoints[token].add(tokens.mul(POINT_MULTIPLIER).div(_totalSupply.sub(accounts[address(0)].balance)));
        unclaimedDividends[token] = unclaimedDividends[token].add(tokens);
        if (token == address(0)) {
            require(msg.value >= tokens, "Insufficient ETH sent");
            uint refund = msg.value.sub(tokens);
            if (refund > 0) {
                require(msg.sender.send(refund), "ETH refund failure");
            }
        } else {
            require(ERC20(token).transferFrom(msg.sender, address(this), tokens), "ERC20 transferFrom failure");
        }
        emit DividendDeposited(token, tokens);
    }
    /// @notice Received ETH as dividends
    receive () external payable {
        depositDividend(address(0), msg.value);
    }

    function _withdrawDividendsFor(address account, address destination) internal {
        updateAccount(account);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint tokens = accounts[account].owing[dividendToken.token];
                if (tokens > 0) {
                    accounts[account].owing[dividendToken.token] = 0;
                    if (dividendToken.token == address(0)) {
                        require(payable(destination).send(tokens), "ETH send failure");
                    } else {
                        require(ERC20(dividendToken.token).transfer(destination, tokens), "ERC20 transfer failure");
                    }
                    emit DividendWithdrawn(account, destination, dividendToken.token, tokens);
                }
            }
        }
    }
    /// @notice Withdraw enabled dividends tokens
    function withdrawDividends() public {
        _withdrawDividendsFor(msg.sender, msg.sender);
    }
    /// @notice Withdraw enabled and disabled dividends tokens
    function withdrawDividendByToken(address token) public {
        updateAccount(msg.sender);
        uint tokens = accounts[msg.sender].owing[token];
        if (tokens > 0) {
            accounts[msg.sender].owing[token] = 0;
            if (token == address(0)) {
                require(payable(msg.sender).send(tokens), "ETH send failure");
            } else {
                require(ERC20(token).transfer(msg.sender, tokens), "ERC20 transfer failure");
            }
        }
        emit DividendWithdrawn(msg.sender, msg.sender, token, tokens);
    }

    /// @notice Mint tokens
    function mint(address tokenOwner, uint tokens) override external permitted(ROLE_MINTTOKENS, tokens) returns (bool success) {
        updateAccount(tokenOwner);
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    /// @notice Burn tokens
    function burn(uint tokens) override external returns (bool success) {
        updateAccount(msg.sender);
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    /// @notice Withdraw enabled dividends tokens before burning
    function burnFrom(address tokenOwner, uint tokens) override external permitted(ROLE_BURNTOKENS, tokens) returns (bool success) {
        require(accounts[tokenOwner].balance >= tokens, "Insufficient tokens");
        _withdrawDividendsFor(tokenOwner, tokenOwner);
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }

    /// @notice Recover tokens for non enabled dividend tokens
    function recoverTokens(address token, uint tokens) public permitted(ROLE_RECOVERTOKENS, 0) {
        DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[token];
        require(dividendToken.timestamp == 0 || !dividendToken.enabled, "Cannot recover tokens for enabled dividend token");
        if (token == address(0)) {
            require(payable(msg.sender).send((tokens == 0 ? address(this).balance : tokens)), "ETH send failure");
        } else {
            require(ERC20(token).transfer(msg.sender, tokens == 0 ? ERC20(token).balanceOf(address(this)) : tokens), "ERC20 transfer failure");
        }
    }
}
