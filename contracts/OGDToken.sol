pragma solidity ^0.7.0;
// pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./Permissioned.sol";
import "./OGDTokenInterface.sol";
import "./TokenList.sol";


/// @notice Optino Governance Dividend Token = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGDToken is OGDTokenInterface, Permissioned {
    using SafeMath for uint;
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
        return _totalSupply.sub(accounts[address(0)].balance);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        _updateAccount(msg.sender);
        _updateAccount(to);
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
        _updateAccount(from);
        _updateAccount(to);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[from].balance = accounts[from].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
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
        uint newDividendPoints = totalDividendPoints[dividendToken].sub(accounts[account].lastDividendPoints[dividendToken]);
        return accounts[account].balance.mul(newDividendPoints).div(POINT_MULTIPLIER);
    }
    function _updateAccount(address account) internal {
        for (uint i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
            if (dividendToken.enabled) {
                uint newOwing = _newDividendsOwing(dividendToken.token, account);
                if (newOwing > 0) {
                    unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing);
                    accounts[account].owing[dividendToken.token] = accounts[account].owing[dividendToken.token].add(newOwing);
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
        require(__totalSupply() > accounts[address(0)].balance, "totalSupply 0");
        require(_dividendToken.enabled, "Dividend token not enabled");
        totalDividendPoints[token] = totalDividendPoints[token].add(tokens.mul(POINT_MULTIPLIER).div(__totalSupply()));
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
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    /// @notice Burn tokens
    function burn(uint tokens) override external returns (bool success) {
        _updateAccount(msg.sender);
        _withdrawDividendsFor(msg.sender, msg.sender);
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
    /// @notice Withdraw enabled dividends tokens before burning
    function burnFrom(address tokenOwner, uint tokens) override external permitted(Roles.BurnTokens, tokens) returns (bool success) {
        require(accounts[tokenOwner].balance >= tokens, "Insufficient tokens");
        _withdrawDividendsFor(tokenOwner, tokenOwner);
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
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
