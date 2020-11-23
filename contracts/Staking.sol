pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./SafeMath.sol";
import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./StakingFactoryInterface.sol";
import "./Owned.sol";
import "./InterestUtils.sol";
import "./CurveInterface.sol";

// SPDX-License-Identifier: GPLv2
contract Staking is ERC20, Owned, InterestUtils {
    using SafeMath for uint;

    // Contracts { dataType 0, address contractAddress, string name }
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
        uint rate; // max uint64 = 18_446744073_709551615 = 1800%
        uint balance;
    }

    bytes constant SYMBOLPREFIX = "OGS";
    uint8 constant DASH = 45;
    uint8 constant ZERO = 48;
    uint constant MAXSTAKINGINFOSTRINGLENGTH = 8;

    uint public id;
    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public stakingRewardCurve;
    StakingInfo public stakingInfo;

    uint _totalSupply;
    mapping(address => Account) public accounts;
    address[] public accountsIndex;

    uint public weightedEndNumerator;
    // uint public weightedDurationDenominator;
    uint public slashingFactor;

    event StakingRewardCurveUpdated(CurveInterface indexed stakingRewardCurve);
    event Staked(address indexed tokenOwner, uint tokens, uint duration, uint end);
    event Unstaked(address indexed tokenOwner, uint tokens, uint reward, uint tokensWithSlashingFactor, uint rewardWithSlashingFactor);
    event Slashed(uint slashingFactor, uint tokensBurnt);

    constructor() {
    }
    function initStaking(uint _id, OGTokenInterface _ogToken, OGDTokenInterface _ogdToken, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) public {
        initOwned(msg.sender);
        id = _id;
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        stakingRewardCurve = CurveInterface(0);
        stakingInfo = StakingInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }

    function symbol() override external view returns (string memory _symbol) {
        bytes memory b = new bytes(7 + SYMBOLPREFIX.length);
        uint i;
        uint j;
        uint num;
        for (i = 0; i < SYMBOLPREFIX.length; i++) {
            b[j++] = SYMBOLPREFIX[i];
        }
        i = 7;
        do {
            i--;
            num = id / 10**i;
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
        require(false, "Unimplemented");
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        require(false, "Unimplemented");
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        require(false, "Unimplemented");
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address /*tokenOwner*/, address /*spender*/) override external pure returns (uint remaining) {
        return 0;
    }

    function setStakingRewardCurve(CurveInterface _stakingRewardCurve) public onlyOwner {
        stakingRewardCurve = _stakingRewardCurve;
        emit StakingRewardCurveUpdated(_stakingRewardCurve);
    }
    function _getRate(uint term) internal view returns (uint rate) {
        if (stakingRewardCurve == CurveInterface(0)) {
            try StakingFactoryInterface(owner).getStakingRewardCurve().getRate(term) returns (uint _rate) {
                rate = _rate;
            } catch {
                rate = 0;
            }
        } else {
            try stakingRewardCurve.getRate(term) returns (uint _rate) {
                rate = _rate;
            } catch {
                rate = 0;
            }
        }
    }
    function getRate(uint term) external view returns (uint rate) {
        rate = _getRate(term);
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

    // function computeWeight(Account memory account) internal pure returns (uint _weight) {
    //     _weight = account.balance.mul(account.duration).div(365 days);
    // }
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
        return _calculateReward(accounts[tokenOwner]);
    }

    function _calculateReward(Account memory account) internal view returns (uint _reward, uint _term) {
        uint from = account.end == 0 ? block.timestamp : uint(account.end).sub(uint(account.duration));
        uint futureValue = InterestUtils.futureValue(account.balance, from, block.timestamp, account.rate);
        _reward = futureValue.sub(account.balance);
        _term = block.timestamp.sub(from);
    }

    function _changeStake(address tokenOwner, uint depositTokens, uint withdrawTokens, bool withdrawRewards, uint duration) internal {
        // console.log("        >   _changeStake(tokenOwner %s, depositTokens %s, withdrawTokens %s,", tokenOwner, depositTokens, withdrawTokens);
        // console.log("              withdrawRewards %s, duration %s)", withdrawRewards, duration);
        Account storage account = accounts[tokenOwner];

        // stakeThroughFactory(...), stake(tokens, duration) or restake(duration)
        if (depositTokens == 0 && withdrawTokens == 0 || depositTokens > 0) {
            require(slashingFactor == 0, "Cannot stake if already slashed");
            require(duration > 0, "Duration must be > 0");
        }
        // unstake(tokens) or unstakeAll()
        if (withdrawTokens > 0) {
            require(uint(account.end) < block.timestamp, "Staking period still active");
            require(withdrawTokens <= account.balance, "Unsufficient staked balance");
        }
        updateStatsBefore(account, tokenOwner);
        (uint reward, /*uint term*/) = _calculateReward(account);
        uint rewardWithSlashingFactor;
        uint availableToMint = StakingFactoryInterface(owner).availableOGTokensToMint();
        if (reward > availableToMint) {
            reward = availableToMint;
        }
        if (withdrawRewards) {
            if (reward > 0) {
                rewardWithSlashingFactor = reward.sub(reward.mul(slashingFactor).div(1e18));
                StakingFactoryInterface(owner).mintOGTokens(tokenOwner, rewardWithSlashingFactor);
            }
        } else {
            if (reward > 0) {
                StakingFactoryInterface(owner).mintOGTokens(address(this), reward);
                account.balance = account.balance.add(reward);
                _totalSupply = _totalSupply.add(reward);
                StakingFactoryInterface(owner).mintOGDTokens(tokenOwner, reward);
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if (depositTokens == 0 && withdrawTokens == 0 || depositTokens > 0) {
            if (account.end == 0) {
                uint rate = _getRate(duration);
                accounts[tokenOwner] = Account(uint64(duration), uint64(block.timestamp.add(duration)), uint64(accountsIndex.length), rate, depositTokens);
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
                emit Staked(tokenOwner, depositTokens, duration, account.end);
            } else {
                require(block.timestamp + duration >= account.end, "Cannot shorten duration");
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp.add(duration));
                account.rate = _getRate(duration);
                account.balance = account.balance.add(depositTokens);
            }
            if (depositTokens > 0) {
                StakingFactoryInterface(owner).mintOGDTokens(tokenOwner, depositTokens);
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
                address lastAccountAddress = accountsIndex[lastIndex];
                accountsIndex[removedIndex] = lastAccountAddress;
                accounts[lastAccountAddress].index = uint64(removedIndex);
                delete accountsIndex[lastIndex];
                delete accounts[tokenOwner];
                if (accountsIndex.length > 0) {
                    accountsIndex.pop();
                }
            }
            account.duration = uint64(0);
            account.end = uint64(block.timestamp);
            StakingFactoryInterface(owner).burnFromOGDTokens(tokenOwner, withdrawTokens);
            uint tokensWithSlashingFactor = withdrawTokens.sub(withdrawTokens.mul(slashingFactor).div(1e18));
            require(ogToken.transfer(tokenOwner, tokensWithSlashingFactor), "OG transfer failed");
            emit Unstaked(msg.sender, withdrawTokens, reward, tokensWithSlashingFactor, rewardWithSlashingFactor);
        }
        updateStatsAfter(account, tokenOwner);
    }

    function stakeThroughFactory(address tokenOwner, uint tokens, uint duration) public onlyOwner {
        require(tokens > 0, "tokens must be > 0");
        _changeStake(tokenOwner, tokens, 0, false, duration);
    }
    function stake(uint tokens, uint duration) public {
        require(tokens > 0, "tokens must be > 0");
        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        _changeStake(msg.sender, tokens, 0, false, duration);
    }
    function restake(uint duration) public {
        require(accounts[msg.sender].balance > 0, "No balance to restake");
        _changeStake(msg.sender, 0, 0, false, duration);
    }
    function unstake(uint tokens) public {
        if (tokens == 0) {
            tokens = accounts[msg.sender].balance;
            uint ogdTokens = ogdToken.balanceOf(msg.sender);
            if (ogdTokens < tokens) {
                tokens = ogdTokens;
            }
        }
        require(accounts[msg.sender].balance >= tokens, "Insufficient tokens to unstake");
        _changeStake(msg.sender, 0, tokens, tokens == accounts[msg.sender].balance, 0);
        emit Transfer(msg.sender, address(0), tokens);
    }
    function slash(uint _slashingFactor) public onlyOwner {
        require(_slashingFactor <= 1e18, "Cannot slash more than 100%");
        require(slashingFactor == 0, "Cannot slash more than once");
        slashingFactor = _slashingFactor;
        uint tokensToBurn = _totalSupply.mul(slashingFactor).div(1e18);
        require(ogToken.burn(tokensToBurn), "OG burn failed");
        emit Slashed(_slashingFactor, tokensToBurn);
    }
}

/*
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
}
function _subStake(uint tokens, bytes32 stakingKey) internal {
    Account storage committment = accounts[msg.sender];
    require(committment.tokens > 0, "OptinoGov: Commit and stake tokens before unstaking");
    committment.staked = committment.staked.sub(tokens);
}
*/
