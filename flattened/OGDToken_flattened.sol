// File: contracts/Permissioned.sol

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned {

    enum Roles {
        SetPermission,
        SetConfig,
        MintTokens,
        BurnTokens,
        RecoverTokens,
        TransferTokens
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
        require(permission.active == uint8(1) && (permission.maximum == 0 || permission.processed + tokens <= permission.maximum), "Not permissioned");
        permission.processed += tokens;
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


/// @notice OGDTokenInterface = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}

// File: contracts/TokenList.sol

pragma solidity ^0.8.0;

/// @notice TokenList to map [token] => [enabled]
// SPDX-License-Identifier: GPLv2
library TokenList {
    struct Token {
        uint timestamp;
        uint index;
        address token;
        bool enabled;
    }
    struct Data {
        bool initialised;
        mapping(address => Token) entries;
        address[] index;
    }

    event TokenAdded(address indexed token, bool enabled);
    event TokenRemoved(address indexed token);
    event TokenUpdated(address indexed token, bool enabled);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function add(Data storage self, address token, bool enabled) internal {
        require(self.entries[token].timestamp == 0, "Cannot add duplicate");
        self.index.push(token);
        self.entries[token] = Token(block.timestamp, self.index.length - 1, token, enabled);
        emit TokenAdded(token, enabled);
    }
    function remove(Data storage self, address token) internal {
        require(self.entries[token].timestamp > 0, "Not registered");
        uint removeIndex = self.entries[token].index;
        emit TokenRemoved(token);
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
        Token storage entry = self.entries[token];
        require(entry.timestamp > 0, "Not registered");
        entry.timestamp = block.timestamp;
        entry.enabled = enabled;
        emit TokenUpdated(token, enabled);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}

// File: contracts/OGDToken.sol

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix





/// @notice Optino Governance Dividend Token = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGDToken is OGDTokenInterface, Permissioned {
    using TokenList for TokenList.Data;
    using TokenList for TokenList.Token;

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

    TokenList.Data private dividendTokens;

    uint private constant POINT_MULTIPLIER = 10e27;
    mapping(address => uint) public totalDividendPoints;
    mapping(address => uint) public unclaimedDividends;

    event UpdateAccountInfo(address dividendToken, address account, uint owing, uint totalOwing, uint lastDividendPoints, uint totalDividendPoints, uint unclaimedDividends);
    event DividendDeposited(address indexed token, uint tokens);
    event DividendWithdrawn(address indexed account, address indexed destination, address indexed token, uint tokens);

    // Duplicated from the library for ABI generation
    event TokenAdded(address indexed token, bool enabled);
    event TokenRemoved(address indexed token);
    event TokenUpdated(address indexed token, bool enabled);

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
        return __totalSupply();
    }
    function __totalSupply() internal view returns (uint) {
        return _totalSupply - accounts[address(0)].balance;
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) override external permitted(Roles.TransferTokens, tokens) returns (bool success) {
        _updateAccount(msg.sender);
        _updateAccount(to);
        accounts[msg.sender].balance -= tokens;
        accounts[to].balance += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external permitted(Roles.TransferTokens, tokens) returns (bool success) {
        _updateAccount(from);
        _updateAccount(to);
        allowed[from][msg.sender] -= tokens;
        accounts[from].balance -= tokens;
        accounts[to].balance += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function addDividendToken(address _dividendToken) external permitted(Roles.SetConfig, 0) {
        if (!dividendTokens.initialised) {
            dividendTokens.init();
        }
        dividendTokens.add(_dividendToken, true);
    }
    function updateToken(address token, bool enabled) public permitted(Roles.SetConfig, 0) {
        require(dividendTokens.initialised);
        dividendTokens.update(token, enabled);
    }
    function removeToken(address token) public permitted(Roles.SetConfig, 0) {
        require(dividendTokens.initialised);
        dividendTokens.remove(token);
    }
    function getDividendTokenByIndex(uint i) public view returns (address, bool) {
        require(i < dividendTokens.length(), "Invalid index");
        TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
        return (dividendToken.token, dividendToken.enabled);
    }
    function dividendTokensLength() public view returns (uint) {
        return dividendTokens.length();
    }

    /// @notice Dividends owning since the last _updateAccount(...) + new dividends owing since the last _updateAccount(...)
    function dividendsOwing(address account) public view returns (address[] memory tokenList, uint[] memory owingList, uint[] memory newOwingList) {
        tokenList = new address[](dividendTokens.index.length);
        owingList = new uint[](dividendTokens.index.length);
        newOwingList = new uint[](dividendTokens.index.length);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            tokenList[i] = dividendToken.token;
            owingList[i] = accounts[account].owing[dividendToken.token];
            newOwingList[i] = _newDividendsOwing(dividendToken.token, account);
        }
    }
    /// @notice New dividends owing since the last _updateAccount(...)
    function _newDividendsOwing(address dividendToken, address account) internal view returns (uint) {
        uint newDividendPoints = totalDividendPoints[dividendToken] - accounts[account].lastDividendPoints[dividendToken];
        return accounts[account].balance * newDividendPoints / POINT_MULTIPLIER;
    }
    function _updateAccount(address account) internal {
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint newOwing = _newDividendsOwing(dividendToken.token, account);
                if (newOwing > 0) {
                    unclaimedDividends[dividendToken.token] -= newOwing;
                    accounts[account].owing[dividendToken.token] += newOwing;
                }
                accounts[account].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
            }
        }
    }
    // function _updateAccounts(address account1, address account2) internal {
    //     for (uint i = 0; i < dividendTokens.index.length; i++) {
    //         TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
    //         if (dividendToken.enabled) {
    //             uint newOwing1 = _newDividendsOwing(dividendToken.token, account1);
    //             if (newOwing1 > 0) {
    //                 unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing1);
    //                 accounts[account1].owing[dividendToken.token] = accounts[account1].owing[dividendToken.token].add(newOwing1);
    //             }
    //             accounts[account1].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
    //             if (account1 != account2) {
    //                 uint newOwing2 = _newDividendsOwing(dividendToken.token, account2);
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
        TokenList.Token memory _dividendToken = dividendTokens.entries[token];
        require(__totalSupply() > 0, "totalSupply 0");
        require(_dividendToken.enabled, "Dividend token not enabled");
        totalDividendPoints[token] += tokens * POINT_MULTIPLIER / __totalSupply();
        unclaimedDividends[token] += tokens;
        if (token == address(0)) {
            require(msg.value >= tokens, "Insufficient ETH sent");
            uint refund = msg.value - tokens;
            if (refund > 0) {
                require(payable(msg.sender).send(refund), "ETH refund failure");
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
        _updateAccount(account);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
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
        _updateAccount(msg.sender);
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
    function mint(address tokenOwner, uint tokens) override external permitted(Roles.MintTokens, tokens) returns (bool success) {
        _updateAccount(tokenOwner);
        accounts[tokenOwner].balance += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    /// @notice Burn tokens
    function burn(uint tokens) override external returns (bool success) {
        _updateAccount(msg.sender);
        _withdrawDividendsFor(msg.sender, msg.sender);
        accounts[msg.sender].balance -= tokens;
        _totalSupply -= tokens;
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    /// @notice Withdraw enabled dividends tokens before burning
    function burnFrom(address tokenOwner, uint tokens) override external permitted(Roles.BurnTokens, tokens) returns (bool success) {
        require(accounts[tokenOwner].balance >= tokens, "Insufficient tokens");
        _withdrawDividendsFor(tokenOwner, tokenOwner);
        accounts[tokenOwner].balance -= tokens;
        _totalSupply -= tokens;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }

    /// @notice Recover tokens for non enabled dividend tokens
    function recoverTokens(address token, uint tokens) public permitted(Roles.RecoverTokens, 0) {
        TokenList.Token memory dividendToken = dividendTokens.entries[token];
        require(dividendToken.timestamp == 0 || !dividendToken.enabled, "Cannot recover tokens for enabled dividend token");
        if (token == address(0)) {
            require(payable(msg.sender).send((tokens == 0 ? address(this).balance : tokens)), "ETH send failure");
        } else {
            require(ERC20(token).transfer(msg.sender, tokens == 0 ? ERC20(token).balanceOf(address(this)) : tokens), "ERC20 transfer failure");
        }
    }
}
