// File: contracts/Owned.sol

pragma solidity ^0.7.0;

/// @notice Ownership
// SPDX-License-Identifier: GPLv2
contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed to);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised, "Already initialised");
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(_owner);
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

// File: contracts/OGDTokenInterface.sol

pragma solidity ^0.7.0;


/// @notice OGDTokenInterface = ERC20 + mint + burn (+ dividend payment)
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
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

// import "https://github.com/ogDAO/Governance/blob/master/contracts/Permissioned.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGDTokenInterface.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/DividendTokens.sol";





/// @notice Optino Governance Dividend Token = ERC20 + mint + burn + dividend payments. (c) The Optino Project 2020
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

    string _symbol;
    string  _name;
    uint8 _decimals;
    uint _totalSupply;
    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint)) allowed;

    DividendTokens.Data private dividendTokens;

    uint public constant pointMultiplier = 10e27;
    mapping(address => uint) public totalDividendPoints;
    mapping(address => uint) public unclaimedDividends;

    event UpdateAccountInfo(address dividendToken, address account, uint owing, uint totalOwing, uint lastDividendPoints, uint totalDividendPoints, uint unclaimedDividends);
    event DividendDeposited(address indexed token, uint tokens);
    event DividendWithdrawn(address indexed account, address indexed token, uint tokens);

    // Duplicated from the library for ABI generation
    event DividendTokenAdded(address indexed token, bool enabled);
    event DividendTokenRemoved(address indexed token);
    event DividendTokenUpdated(address indexed token, bool enabled);

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
        updateAccounts(msg.sender, to);
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
        updateAccounts(msg.sender, to);
        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function addDividendToken(address _dividendToken) external onlyOwner {
        if (!dividendTokens.initialised) {
            dividendTokens.init();
        }
        dividendTokens.add(_dividendToken, true);
    }
    function updateDividendToken(address token, bool enabled) public onlyOwner {
        require(dividendTokens.initialised);
        dividendTokens.update(token, enabled);
    }
    function removeDividendToken(address token) public onlyOwner {
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

    /// @notice New dividends owing since the last updateAccount(...)
    function newDividendsOwing(address dividendToken, address account) internal view returns (uint) {
        uint newDividendPoints = totalDividendPoints[dividendToken].sub(accounts[account].lastDividendPoints[dividendToken]);
        return accounts[account].balance.mul(newDividendPoints).div(pointMultiplier);
    }
    /// @notice Dividends owning since the last updateAccount(...) + new dividends owing since the last updateAccount(...)
    function dividendsOwing(address account) public view returns (address[] memory tokenList, uint[] memory owingList) {
        tokenList = new address[](dividendTokens.index.length);
        owingList = new uint[](dividendTokens.index.length);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            uint owing = accounts[account].owing[dividendToken.token].add(newDividendsOwing(dividendToken.token, account));
            tokenList[i] = dividendToken.token;
            owingList[i] = owing;
        }
    }
    function updateAccounts(address account1, address account2) internal {
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint owing = newDividendsOwing(dividendToken.token, account1);
                if (owing > 0) {
                    unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(owing);
                    accounts[account1].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
                    accounts[account1].owing[dividendToken.token] = accounts[account1].owing[dividendToken.token].add(owing);
                }
                if (account1 != account2) {
                    owing = newDividendsOwing(dividendToken.token, account2);
                    if (owing > 0) {
                        unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(owing);
                        accounts[account2].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
                        accounts[account2].owing[dividendToken.token] = accounts[account2].owing[dividendToken.token].add(owing);
                    }
                }
            }
        }
    }

    /// @notice Deposit enabled dividend token
    function depositDividend(address token, uint tokens) public payable {
        DividendTokens.DividendToken memory _dividendToken = dividendTokens.entries[token];
        require(_dividendToken.enabled, "Dividend token is not enabled");
        totalDividendPoints[token] = totalDividendPoints[token].add(tokens.mul(pointMultiplier).div(_totalSupply));
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

    function withdrawDividendsFor(address account) internal {
        updateAccounts(account, account);
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint tokens = accounts[account].owing[dividendToken.token];
                if (tokens > 0) {
                    accounts[account].owing[dividendToken.token] = 0;
                    if (dividendToken.token == address(0)) {
                        require(payable(account).send(tokens), "ETH send failure");
                    } else {
                        require(ERC20(dividendToken.token).transfer(account, tokens), "ERC20 transfer failure");
                    }
                }
                emit DividendWithdrawn(account, dividendToken.token, tokens);
            }
        }
    }
    /// @notice Withdraw enabled dividends tokens
    function withdrawDividends() public {
        withdrawDividendsFor(msg.sender);
    }
    /// @notice Withdraw enabled and disabled dividends tokens. Does not include new dividends since last updateAccount(...) triggered by transfer(...) and transferFrom(...)
    function withdrawDividend(address token) public {
        uint tokens = accounts[msg.sender].owing[token];
        if (tokens > 0) {
            accounts[msg.sender].owing[token] = 0;
            if (token == address(0)) {
                require(payable(msg.sender).send(tokens), "ETH send failure");
            } else {
                require(ERC20(token).transfer(msg.sender, tokens), "ERC20 transfer failure");
            }
        }
        emit DividendWithdrawn(msg.sender, token, tokens);
    }

    /// @notice Mint tokens
    function mint(address tokenOwner, uint tokens) override external permitted(ROLE_MINTER, tokens) returns (bool success) {
        processed(ROLE_MINTER, tokens);
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        updateAccounts(tokenOwner, tokenOwner);
        return true;
    }
    /// @notice Withdraw dividends and then burn tokens
    function burn(uint tokens) override external returns (bool success) {
        updateAccounts(msg.sender, msg.sender);
        withdrawDividendsFor(msg.sender);
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

    /// @notice Recover tokens for non enabled dividend tokens
    function recoverTokens(address token, uint tokens) public onlyOwner {
        DividendTokens.DividendToken memory dividendToken = dividendTokens.entries[token];
        require(dividendToken.timestamp == 0 || !dividendToken.enabled, "Cannot recover tokens for enabled dividend token");
        if (token == address(0)) {
            require(payable(owner).send((tokens == 0 ? address(this).balance : tokens)), "ETH send failure");
        } else {
            require(ERC20(token).transfer(owner, tokens == 0 ? ERC20(token).balanceOf(address(this)) : tokens), "ERC20 transfer failure");
        }
    }
}
