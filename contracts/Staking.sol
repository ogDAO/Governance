pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./SafeMath.sol";
import "./OGTokenInterface.sol";
import "./StakingFactoryInterface.sol";
import "./Owned.sol";
import "./InterestUtils.sol";

// SPDX-License-Identifier: GPLv2
contract Staking is ERC20, Owned {
    using SafeMath for uint;

    // Token { dataType 1, address tokenAddress }
    // Feed { dataType 2, address feedAddress, uint feedType, uint feedDecimals, string name }
    // Conventions { dataType 3, address [token0, token1], address [feed0, feed1], uint[6] [type0, type1, decimals0, decimals1, inverse0, inverse1], string [feed0Name, feedName2, Market, Convention] }
    // General { dataType 4, address[4] addresses, address [feed0, feed1], uint[6] uints, string[4] strings }
    struct StakingInfo {
        uint dataType;
        address[4] addresses;
        uint[6] uints;
        string string0; // TODO: Check issues using string[4] strings
        string string1;
        string string2;
        string string3;
    }

    struct Account {
        uint64 duration;
        uint64 end;
        uint64 index;
        uint64 rate; // max 18_446744073_709551615 = 1800%
        uint balance;
    }

    bytes constant SYMBOLPREFIX = "OGS";
    uint8 constant DASH = 45;
    uint8 constant ZERO = 48;
    uint constant MAXSTAKINGINFOSTRINGLENGTH = 8;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 365;

    uint public id;
    OGTokenInterface public ogToken;
    StakingInfo public stakingInfo;
    mapping(address => Account) public accounts;
    address[] public accountsIndex;
    uint public weightedEndNumerator;
    // uint public weightedDurationDenominator;
    uint public slashingFactor;
    uint public _totalSupply;
    mapping(address => mapping(address => uint)) allowed;

    uint public rewardsPerSecond = 150_000_000_000_000_000; // 0.15
    uint public rewardsPerYear;

    event Staked(address indexed tokenOwner, uint tokens, uint duration, uint end);
    event Unstaked(address indexed tokenOwner, uint tokens, uint reward, uint tokensWithSlashingFactor, uint rewardWithSlashingFactor);
    event Slashed(uint slashingFactor, uint tokensBurnt);

    constructor() {
    }
    function initStaking(uint _id, OGTokenInterface _ogToken, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) public {
        initOwned(msg.sender);
        id = _id;
        ogToken = _ogToken;
        stakingInfo = StakingInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
        // rewardsPerYear = 15 * 10**16; // 15%
        rewardsPerYear = SECONDS_PER_YEAR * 10**10; // 15%
    }

    function symbol() override external view returns (string memory _symbol) {
        bytes memory b = new bytes(20);
        uint i;
        uint j;
        uint num;
        for (i = 0; i < SYMBOLPREFIX.length; i++) {
            b[j++] = SYMBOLPREFIX[i];
        }
        i = 7;
        do {
            i--;
            num = id / 10 ** i;
            b[j++] = byte(uint8(num % 10 + ZERO));
        } while (i > 0);
        _symbol = string(b);
    }
    function name() override external view returns (string memory) {
        uint i;
        uint j;
        bytes memory b = new bytes(4 + MAXSTAKINGINFOSTRINGLENGTH);
        for (i = 0; i < SYMBOLPREFIX.length; i++) {
            b[j++] = SYMBOLPREFIX[i];
        }
        b[j++] = byte(DASH);
        bytes memory b1 = bytes(stakingInfo.string0);
        for (i = 0; i < b1.length && i < MAXSTAKINGINFOSTRINGLENGTH; i++) {
            b[j++] = b1[i];
        }
        return string(b);
    }
    function decimals() override external pure returns (uint8) {
        return 18;
    }
    function totalSupply() override external view returns (uint) {
        return _totalSupply.sub(accounts[address(0)].balance);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        revert("not implemented");
        // require(block.timestamp > accounts[msg.sender].end, "Stake period not ended");
        // // weightedEndNumerator = weightedEndNumerator.sub(uint(accounts[msg.sender].end).mul(accounts[msg.sender].balance));
        // accounts[msg.sender].end = uint64(block.timestamp);
        // accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        // updateStatsBefore(accounts[msg.sender], msg.sender);
        // updateStatsBefore(accounts[to], to);
        // // weightedEndNumerator = weightedEndNumerator.add(uint(accounts[msg.sender].end).mul(accounts[msg.sender].balance));
        // if (accounts[to].end == 0) {
        //     accounts[to] = Account(uint64(0), uint64(block.timestamp), uint64(accountsIndex.length), uint64(0), tokens);
        //     accountsIndex.push(to);
        // } else {
        //     // weightedEndNumerator = weightedEndNumerator.sub(uint(accounts[to].end).mul(accounts[to].balance));
        //     accounts[to].balance = accounts[to].balance.add(tokens);
        //     // weightedEndNumerator = weightedEndNumerator.add(uint(accounts[to].end).mul(accounts[to].balance));
        // }
        // updateStatsAfter(accounts[msg.sender], msg.sender);
        // updateStatsAfter(accounts[to], to);
        // emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        revert("not implemented");
        // require(block.timestamp > accounts[from].end, "Stake period not ended");
        // weightedEndNumerator = weightedEndNumerator.sub(uint(accounts[from].end).mul(accounts[from].balance));
        // accounts[from].end = uint64(block.timestamp);
        // accounts[from].balance = accounts[from].balance.sub(tokens);
        // allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        // if (accounts[to].end == 0) {
        //     accounts[to] = Account(uint64(0), uint64(block.timestamp), uint64(accountsIndex.length), uint64(0), tokens);
        //     accountsIndex.push(to);
        // } else {
        //     weightedEndNumerator = weightedEndNumerator.sub(uint(accounts[to].end).mul(accounts[to].balance));
        //     accounts[to].balance = accounts[to].balance.add(tokens);
        //     weightedEndNumerator = weightedEndNumerator.add(uint(accounts[to].end).mul(accounts[to].balance));
        // }
        // emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function getStakingInfo() public view returns (uint dataType, address[4] memory addresses, uint[6] memory uints, string memory string0, string memory string1, string memory string2, string memory string3) {
        (dataType, addresses, uints) = (stakingInfo.dataType, stakingInfo.addresses, stakingInfo.uints);
        string0 = stakingInfo.string0;
        string1 = stakingInfo.string1;
        string2 = stakingInfo.string2;
        string3 = stakingInfo.string3;
    }
    function getAccountByIndex(uint i) public view returns (address tokenOwner, Account memory account) {
        require(i < accountsIndex.length, "Invalid index");
        tokenOwner = accountsIndex[i];
        account = accounts[tokenOwner];
    }
    function accountsLength() public view returns (uint) {
        return accountsIndex.length;
    }
    function weightedEnd() public view returns (uint _weightedEnd) {
        if (_totalSupply > 0) {
            _weightedEnd = weightedEndNumerator.div(_totalSupply.sub(accounts[address(0)].balance));
        }
        if (_weightedEnd < block.timestamp) {
            _weightedEnd = block.timestamp;
        }
    }

    function computeWeight(Account memory account) internal pure returns (uint _weight) {
        _weight = account.balance.mul(account.duration).div(SECONDS_PER_YEAR);
    }
    function updateStatsBefore(Account memory account, address tokenOwner) internal {
        weightedEndNumerator = weightedEndNumerator.sub(uint(account.end).mul(tokenOwner == address(0) ? 0 : account.balance));
        // uint weightedDuration = computeWeight(account);
        // console.log("        > updateStatsBefore(%s).weightedDuration: ", tokenOwner, weightedDuration);
        // weightedDurationDenominator = weightedDurationDenominator.sub(weightedDuration);
    }
    function updateStatsAfter(Account memory account, address tokenOwner) internal {
        weightedEndNumerator = weightedEndNumerator.add(uint(account.end).mul(tokenOwner == address(0) ? 0 : account.balance));
        // uint weightedDuration = computeWeight(account);
        // console.log("        > updateStatsAfter(%s).weightedDuration: ", tokenOwner, weightedDuration);
        // weightedDurationDenominator = weightedDurationDenominator.add(weightedDuration);
    }

    // function _stake(address tokenOwner, uint tokens, uint duration) internal {
    //     require(slashingFactor == 0, "Cannot stake if already slashed");
    //     require(duration > 0, "Invalid duration");
    //     Account storage account = accounts[tokenOwner];
    //     updateStatsBefore(account, tokenOwner);
    //     if (account.end == 0) {
    //         console.log("        > _stake(%s) - rewardsPerYear %s", tokenOwner, rewardsPerYear);
    //         accounts[tokenOwner] = Account(uint64(duration), uint64(block.timestamp.add(duration)), uint64(accountsIndex.length), uint64(rewardsPerYear), tokens);
    //         account = accounts[tokenOwner];
    //         accountsIndex.push(tokenOwner);
    //         emit Staked(tokenOwner, tokens, duration, account.end);
    //     } else {
    //         require(block.timestamp + duration >= account.end, "Cannot shorten duration");
    //         _totalSupply = _totalSupply.sub(account.balance);
    //         account.duration = uint64(duration);
    //         account.end = uint64(block.timestamp.add(duration));
    //         account.balance = account.balance.add(tokens);
    //     }
    //     updateStatsAfter(account, tokenOwner);
    //     _totalSupply = _totalSupply.add(account.balance);
    //     emit Transfer(address(0), tokenOwner, tokens);
    // }

    function accruedReward(address tokenOwner) public view returns (uint _reward, uint _term) {
        return computeReward(accounts[tokenOwner], tokenOwner, accounts[tokenOwner].balance);
    }

    function computeReward(Account memory account, address /*tokenOwner*/, uint tokens) internal view returns (uint _reward, uint _term) {
        // console.log("        >     computeReward(tokenOwner %s, tokens %s)", tokenOwner, tokens);
        uint from = account.end == 0 ? block.timestamp : uint(account.end).sub(uint(account.duration));
        uint futureValue = InterestUtils.futureValue(tokens, from, block.timestamp, rewardsPerYear, SECONDS_PER_DAY);
        // console.log("        > computeReward(%s) - tokens %s, rate %s", tokenOwner, tokens, rewardsPerYear);
        // console.log("          from %s, to %s, futureValue %s", from, block.timestamp, futureValue);
        _reward = futureValue.sub(tokens);
        _term = block.timestamp.sub(from);
        // console.log("          _reward %s", _reward);
    }

    function _changeStake(address tokenOwner, uint depositTokens, uint withdrawTokens, bool withdrawRewards, uint duration) internal {
        // console.log("        >   _changeStake(tokenOwner %s, depositTokens %s, withdrawTokens %s,", tokenOwner, depositTokens, withdrawTokens);
        // console.log("              withdrawRewards %s, duration %s)", withdrawRewards, duration);
        Account storage account = accounts[tokenOwner];

        // stakeThroughFactory(...), stake(tokens, duration) or restake(duration)
        if (depositTokens == 0 && withdrawTokens == 0 || depositTokens > 0) {
            require(slashingFactor == 0, "Cannot stake if already slashed");
        }
        // unstake(tokens) or unstakeAll()
        if (withdrawTokens > 0) {
            require(uint(account.end) < block.timestamp, "Staking period still active");
            require(withdrawTokens <= account.balance, "Unsufficient staked balance");
        }
        updateStatsBefore(account, tokenOwner);
        (uint reward, /*uint term*/) = computeReward(account, tokenOwner, account.balance);
        uint rewardWithSlashingFactor;
        // console.log("        >     reward %s", reward);
        if (withdrawRewards) {
            if (reward > 0) {
                rewardWithSlashingFactor = reward.sub(reward.mul(slashingFactor).div(10**18));
                StakingFactoryInterface(owner).mintOGTokens(tokenOwner, rewardWithSlashingFactor);
            }
        } else {
            if (reward > 0) {
                StakingFactoryInterface(owner).mintOGTokens(address(this), reward);
                account.balance = account.balance.add(reward);
                _totalSupply = _totalSupply.add(reward);
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if (depositTokens == 0 && withdrawTokens == 0 || depositTokens > 0) {
            if (account.end == 0) {
                accounts[tokenOwner] = Account(uint64(duration), uint64(block.timestamp.add(duration)), uint64(accountsIndex.length), uint64(rewardsPerYear), depositTokens);
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
                emit Staked(tokenOwner, depositTokens, duration, account.end);
            } else {
                require(block.timestamp + duration >= account.end, "Cannot shorten duration");
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp.add(duration));
                account.balance = account.balance.add(depositTokens);
            }
            if (depositTokens > 0) {
                _totalSupply = _totalSupply.add(depositTokens);
                emit Transfer(address(0), tokenOwner, depositTokens);
            }
        }
        if (withdrawTokens > 0) {
            _totalSupply = _totalSupply.sub(withdrawTokens);
            account.balance = account.balance.sub(withdrawTokens);
            if (account.balance == 0) {
                uint removedIndex = uint(account.index);
                uint lastIndex = accountsIndex.length - 1;
                address lastStakeAddress = accountsIndex[lastIndex];
                accountsIndex[removedIndex] = lastStakeAddress;
                accounts[lastStakeAddress].index = uint64(removedIndex);
                delete accountsIndex[lastIndex];
                if (accountsIndex.length > 0) {
                    accountsIndex.pop();
                }
            // } else {
                // _totalSupply = _totalSupply.add(account.balance);
            }
            // updateStatsAfter(account, tokenOwner);
            uint tokensWithSlashingFactor = withdrawTokens.sub(withdrawTokens.mul(slashingFactor).div(10**18));
            require(ogToken.transfer(tokenOwner, tokensWithSlashingFactor), "OG transfer failed");
            // uint rewardWithSlashingFactor;
            // if (reward > 0) {
            //     rewardWithSlashingFactor = reward.sub(reward.mul(slashingFactor).div(10**18));
            //     StakingFactoryInterface(owner).mintOGTokens(tokenOwner, rewardWithSlashingFactor);
            // }
            emit Unstaked(msg.sender, withdrawTokens, reward, tokensWithSlashingFactor, rewardWithSlashingFactor);
        }
        updateStatsAfter(account, tokenOwner);
        // if (depositTokens > 0) {
        //     _totalSupply = _totalSupply.add(account.balance);
        //     emit Transfer(address(0), tokenOwner, depositTokens);
        // } else {
        // }
    }

    function stakeThroughFactory(address tokenOwner, uint tokens, uint duration) public onlyOwner {
        console.log("        > StakingFactory.stakeThroughFactory(tokenOwner %s, tokens %s, duration %s)", tokenOwner, tokens, duration);
        require(tokens > 0, "tokens must be > 0");
        require(duration > 0, "duration must be > 0");
        _changeStake(tokenOwner, tokens, 0, false, duration);
    }
    function stake(uint tokens, uint duration) public {
        console.log("        > %s -> stake(tokens %s, duration %s)", msg.sender, tokens, duration);
        require(tokens > 0, "tokens must be > 0");
        require(duration > 0, "duration must be > 0");
        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        _changeStake(msg.sender, tokens, 0, false, duration);
    }
    function restake(uint duration) public {
        console.log("        > %s -> restake(duration %s)", msg.sender, duration);
        require(duration > 0, "duration must be > 0");
        require(accounts[msg.sender].balance > 0, "To balance to restake");
        _changeStake(msg.sender, 0, 0, false, duration);
    }
    function unstake(uint tokens) public {
        console.log("        > %s -> unstake(tokens %s)", msg.sender, tokens);
        require(tokens > 0, "tokens must be > 0");
        require(accounts[msg.sender].balance > 0, "To balance to unstake");
        _changeStake(msg.sender, 0, tokens, tokens == ogToken.balanceOf(msg.sender), 0);
        emit Transfer(msg.sender, address(0), tokens);
    }
    function unstakeAll() public {
        uint tokens = accounts[msg.sender].balance;
        console.log("        > %s -> unstakeAll(tokens %s)", msg.sender, tokens);
        require(tokens > 0, "To balance to unstake");
        _changeStake(msg.sender, 0, tokens, true, 0);
        emit Transfer(msg.sender, address(0), tokens);
    }
    function slash(uint _slashingFactor) public onlyOwner {
        require(_slashingFactor <= 10 ** 18, "Cannot slash more than 100%");
        require(slashingFactor == 0, "Cannot slash more than once");
        slashingFactor = _slashingFactor;
        uint tokensToBurn = _totalSupply.mul(slashingFactor).div(10**18);
        require(ogToken.burn(tokensToBurn), "OG burn failed");
        emit Slashed(_slashingFactor, tokensToBurn);
    }
}
