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
    uint constant SECONDS_PER_DAY = 1 days;
    uint constant SECONDS_PER_YEAR = 365 days;

    uint public id;
    OGTokenInterface public ogToken;
    StakingInfo public stakingInfo;

    uint _totalSupply;
    mapping(address => Account) public accounts;
    address[] public accountsIndex;
    mapping(address => mapping(address => uint)) allowed;

    uint public weightedEndNumerator;
    // uint public weightedDurationDenominator;
    uint public slashingFactor;

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
        require(tokens == 0, "Not implemented");
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
        require(tokens == 0, "Not implemented");
        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(from, to, tokens);
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
        return _calculateReward(accounts[tokenOwner], tokenOwner, accounts[tokenOwner].balance);
    }

    function _calculateReward(Account memory account, address /*tokenOwner*/, uint tokens) internal view returns (uint _reward, uint _term) {
        // console.log("        >     _calculateReward(tokenOwner %s, tokens %s)", tokenOwner, tokens);
        uint from = account.end == 0 ? block.timestamp : uint(account.end).sub(uint(account.duration));
        uint futureValue = InterestUtils.futureValue(tokens, from, block.timestamp, rewardsPerYear, SECONDS_PER_DAY);
        // console.log("        > _calculateReward(%s) - tokens %s, rate %s", tokenOwner, tokens, rewardsPerYear);
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
        (uint reward, /*uint term*/) = _calculateReward(account, tokenOwner, account.balance);
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
        // console.log("        > StakingFactory.stakeThroughFactory(tokenOwner %s, tokens %s, duration %s)", tokenOwner, tokens, duration);
        require(tokens > 0, "tokens must be > 0");
        require(duration > 0, "duration must be > 0");
        _changeStake(tokenOwner, tokens, 0, false, duration);
    }
    function stake(uint tokens, uint duration) public {
        // console.log("        > %s -> stake(tokens %s, duration %s)", msg.sender, tokens, duration);
        require(tokens > 0, "tokens must be > 0");
        require(duration > 0, "duration must be > 0");
        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        _changeStake(msg.sender, tokens, 0, false, duration);
    }
    function restake(uint duration) public {
        // console.log("        > %s -> restake(duration %s)", msg.sender, duration);
        require(duration > 0, "duration must be > 0");
        require(accounts[msg.sender].balance > 0, "To balance to restake");
        _changeStake(msg.sender, 0, 0, false, duration);
    }
    function unstake(uint tokens) public {
        // console.log("        > %s -> unstake(tokens %s)", msg.sender, tokens);
        require(tokens > 0, "tokens must be > 0");
        require(accounts[msg.sender].balance > 0, "To balance to unstake");
        _changeStake(msg.sender, 0, tokens, tokens == ogToken.balanceOf(msg.sender), 0);
        emit Transfer(msg.sender, address(0), tokens);
    }
    function unstakeAll() public {
        uint tokens = accounts[msg.sender].balance;
        // console.log("        > %s -> unstakeAll(tokens %s)", msg.sender, tokens);
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

/*
// mapping(bytes32 => StakeInfo) public stakeInfoData;
// bytes32[] public stakeInfoIndex;

// // Token { dataType 1, address tokenAddress }
// // Feed { dataType 2, address feedAddress, uint feedType, uint feedDecimals, string name }
// // Conventions { dataType 3, address [token0, token1], address [feed0, feed1], uint[6] [type0, type1, decimals0, decimals1, inverse0, inverse1], string [feed0Name, feedName2, Market, Convention] }
// // General { dataType 4, address[4] addresses, address [feed0, feed1], uint[6] uints, string[4] strings }
// struct StakeInfo {
//     uint dataType;
//     address[4] addresses;
//     uint[6] uints;
//     string string0; // TODO: Check issues using string[4] strings
//     string string1;
//     string string2;
//     string string3;
// }

struct Account {
    uint64 duration;
    uint64 end;
    uint64 lastDelegated;
    uint64 lastVoted;
    uint balance;
    // uint staked;
    uint votes;
    uint delegatedVotes;
    address delegatee;
}

mapping(address => mapping(bytes32 => uint)) stakes;

event StakeInfoAdded(bytes32 stakingKey, uint dataType, address[4] addresses, uint[6] uints, string string0, string string1, string string2, string string3);
event Staked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
event Unstaked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
event StakeBurnt(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);



function addStakeForToken(uint tokens, address tokenAddress, string memory name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress, name));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
    }
    _addStake(tokens, stakingKey);
}
function subStakeForToken(uint tokens, address tokenAddress, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress, name));
    _subStake(tokens, stakingKey);
}
function addStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(2, [feedAddress, address(0), address(0), address(0)], [uint(feedType), uint(feedDecimals), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 2, [feedAddress, address(0), address(0), address(0)], [uint(feedType), uint(feedDecimals), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
    }
    _addStake(tokens, stakingKey);
}
function subStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
    _subStake(tokens, stakingKey);
}
function addStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, strings[0], strings[1], strings[2], strings[3]));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(3, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 3, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }
    _addStake(tokens, stakingKey);
}
function subStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, strings[0], strings[1], strings[2], strings[3]));
    _subStake(tokens, stakingKey);
}
function addStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }
    _addStake(tokens, stakingKey);
}
function subStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    _subStake(tokens, stakingKey);
}
function _addStake(uint tokens, bytes32 stakingKey) internal {
    Account storage committment = accounts[msg.sender];
    require(committment.tokens > 0, "OptinoGov: Commit before staking");
    require(committment.tokens >= committment.staked + tokens, "OptinoGov: Insufficient tokens to stake");
    committment.staked = committment.staked.add(tokens);
    // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].add(tokens);
    // TODO emit Staked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
}
function _subStake(uint tokens, bytes32 stakingKey) internal {
    Account storage committment = accounts[msg.sender];
    require(committment.tokens > 0, "OptinoGov: Commit and stake tokens before unstaking");
    // TODO require(committment.stakes[stakingKey] >= tokens, "OptinoGov: Insufficient staked tokens");
    committment.staked = committment.staked.sub(tokens);
    // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].sub(tokens);
    // TODO emit Unstaked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
}
function stakeInfoLength() public view returns (uint _stakeInfoLength) {
    _stakeInfoLength = stakeInfoIndex.length;
}
function getStakeInfoByKey(bytes32 stakingKey) public view returns (uint dataType, address[4] memory addresses, uint[6] memory uints, string memory string0, string memory string1, string memory string2, string memory string3) {
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    (dataType, addresses, uints) = (stakeInfo.dataType, stakeInfo.addresses, stakeInfo.uints);
    string0 = stakeInfo.string0;
    string1 = stakeInfo.string1;
    string2 = stakeInfo.string2;
    string3 = stakeInfo.string3;
}
function getStaked(address tokenOwner, bytes32 stakingKey) public view returns (uint _staked) {
    Account storage committment = accounts[tokenOwner];
    // TODO _staked = committment.stakes[stakingKey];
}

function burnStake(address[] calldata tokenOwners, bytes32 stakingKey, uint percent) external onlySelf {
    for (uint i = 0; i < tokenOwners.length; i++) {
        address tokenOwner = tokenOwners[i];
        Account storage committment = accounts[tokenOwner];
        // TODO uint staked = committment.stakes[stakingKey];
        // if (staked > 0) {
        //     uint tokensToBurn = staked * percent / uint(100);
        //     committment.staked = committment.staked.sub(tokensToBurn);
        //     committment.stakes[stakingKey] = committment.stakes[stakingKey].sub(tokensToBurn);
        //     committment.tokens = committment.tokens.sub(tokensToBurn);
        //     require(ogToken.burn(tokensToBurn), "OptinoGov: burn failed");
        //     emit StakeBurnt(tokenOwner, tokensToBurn, committment.stakes[stakingKey], stakingKey);
        // }
    }
}
*/
