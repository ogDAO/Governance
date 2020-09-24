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

// File: contracts/OGDTokenInterface.sol

pragma solidity ^0.7.0;


/// @notice OGDTokenInterface = ERC20 + mint + burn (+ dividend payment)
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
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

// File: contracts/OptinoGov.sol

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGTokenInterface.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGDTokenInterface.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/SafeMath.sol";




// ----------------------------------------------------------------------------
// Optino Governance
//
// Originally based on https://github.com/bartjman/XS2Option/blob/master/contracts/XS2Gov.sol (MIT)
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: GPLv2
// ----------------------------------------------------------------------------

contract OptinoGov {
    using SafeMath for uint;

    struct Lock {
        uint duration;
        uint end;
        uint locked;
        uint votes;
        uint staked;
        mapping(bytes32 => uint) stakes;
    }
    // Token { dataType 1, address tokenAddress }
    // Feed { dataType 2, address feedAddress, uint feedType, uint feedDecimals, string name }
    // Conventions { dataType 3, address [token0, token1], address [feed0, feed1], uint[6] [type0, type1, decimals0, decimals1, inverse0, inverse1], string [feed0Name, feedName2, Market, Convention] }
    // General { dataType 4, address[4] addresses, address [feed0, feed1], uint[6] uints, string[4] strings }
    struct StakeInfo {
        uint dataType;
        address[4] addresses;
        uint[6] uints;
        string string0; // TODO: Check issues using string[4] strings
        string string1;
        string string2;
        string string3;
    }
    struct Proposal {
        uint start;
        address proposer;
        string description;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] data;
        uint forVotes;
        uint againstVotes;
        mapping(address => bool) voted;
        bool executed;
    }

    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    uint public maxLockTerm = 365 days;
    uint public rewardsPerSecond = 150000000000000000;
    uint public proposalCost = 100000000000000000000; // 100 tokens assuming 18 decimals
    uint public proposalThreshold = 1 * 10 ** 15; // 0.1%, 18 decimals
    uint public quorum = 2 * 10 ** 17; // 20%, 18 decimals
    uint public quorumDecayPerSecond = 4 * 10 ** 17 / uint(60 * 60 * 24 * 365); // 40% per year, i.e., 0 in 6 months
    uint public votingDuration = 3 hours; // 3 days;
    uint public executeDelay = 2 hours; // 2 days;
    uint public rewardPool;
    uint public totalVotes;
    mapping(address => Lock) public locks; // Locked tokens per address
    mapping(bytes32 => StakeInfo) public stakeInfoData;
    bytes32[] public stakeInfoIndex;
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;

    event MaxLockTermUpdated(uint maxLockTerm);
    event RewardsPerSecondUpdated(uint rewardsPerSecond);
    event ProposalCostUpdated(uint proposalCost);
    event ProposalThresholdUpdated(uint proposalThreshold);
    event QuorumUpdated(uint quorum);
    event QuorumDecayPerSecondUpdated(uint quorumDecayPerSecond);
    event VotingDurationUpdated(uint votingDuration);
    event ExecuteDelayUpdated(uint executeDelay);

    event Locked(address indexed user, uint tokens, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event StakeInfoAdded(bytes32 stakingKey, uint dataType, address[4] addresses, uint[6] uints, string string0, string string1, string string2, string string3);
    event Staked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event Unstaked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event StakeBurnt(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event Collected(address indexed user, uint elapsed, uint reward, uint rewardPool, uint end, uint duration);
    event Unlocked(address indexed user, uint amount, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event Proposed(address indexed proposer, uint oip, string description, address[] targets, uint[] value, bytes[] data, uint start);
    event Voted(address indexed user, uint oip, bool voteFor, uint forVotes, uint againstVotes);
    event Executed(address indexed user, uint oip);

    modifier onlySelf {
        require(msg.sender == address(this), "Not self");
        _;
    }

    constructor(OGTokenInterface _ogToken, OGDTokenInterface _ogdToken) {
        ogToken = _ogToken;
        ogdToken = _ogdToken;
    }
    function setMaxLockTerm(uint _maxLockTerm) external onlySelf {
        maxLockTerm = _maxLockTerm;
        emit MaxLockTermUpdated(maxLockTerm);
    }
    function setRewardsPerSecond(uint _rewardsPerSecond) external onlySelf {
        rewardsPerSecond = _rewardsPerSecond;
        emit RewardsPerSecondUpdated(rewardsPerSecond);
    }
    function setProposalCost(uint _proposalCost) external onlySelf {
        proposalCost = _proposalCost;
        emit ProposalCostUpdated(proposalCost);
    }
    function setProposalThreshold(uint _proposalThreshold) external onlySelf {
        proposalThreshold = _proposalThreshold;
        emit ProposalThresholdUpdated(proposalThreshold);
    }
    function setQuorum(uint _quorum) external onlySelf {
        quorum = _quorum;
        emit QuorumUpdated(quorum);
    }
    function setQuorumDecayPerSecond(uint _quorumDecayPerSecond) external onlySelf {
        quorumDecayPerSecond = _quorumDecayPerSecond;
        emit QuorumDecayPerSecondUpdated(quorumDecayPerSecond);
    }
    function setVotingDuration(uint _votingDuration) external onlySelf {
        votingDuration = _votingDuration;
        emit VotingDurationUpdated(votingDuration);
    }
    function setExecuteDelay(uint _executeDelay) external onlySelf {
        executeDelay = _executeDelay;
        emit ExecuteDelayUpdated(executeDelay);
    }

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
        Lock storage lock = locks[msg.sender];
        require(lock.locked > 0, "OptinoGov: Lock tokens before staking");
        require(lock.locked >= lock.staked + tokens, "OptinoGov: Insufficient tokens to stake");
        lock.staked = lock.staked.add(tokens);
        lock.stakes[stakingKey] = lock.stakes[stakingKey].add(tokens);
        emit Staked(msg.sender, tokens, lock.stakes[stakingKey], stakingKey);
    }
    function _subStake(uint tokens, bytes32 stakingKey) internal {
        Lock storage lock = locks[msg.sender];
        require(lock.locked > 0, "OptinoGov: Lock and stake tokens before unstaking");
        require(lock.stakes[stakingKey] >= tokens, "OptinoGov: Insufficient staked tokens");
        lock.staked = lock.staked.sub(tokens);
        lock.stakes[stakingKey] = lock.stakes[stakingKey].sub(tokens);
        emit Unstaked(msg.sender, tokens, lock.stakes[stakingKey], stakingKey);
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
        Lock storage lock = locks[tokenOwner];
        _staked = lock.stakes[stakingKey];
    }

    function burnStake(address[] calldata tokenOwners, bytes32 stakingKey, uint percent) external onlySelf {
        for (uint i = 0; i < tokenOwners.length; i++) {
            address tokenOwner = tokenOwners[i];
            Lock storage lock = locks[tokenOwner];
            uint staked = lock.stakes[stakingKey];
            if (staked > 0) {
                uint tokensToBurn = staked * percent / uint(100);
                lock.staked = lock.staked.sub(tokensToBurn);
                lock.stakes[stakingKey] = lock.stakes[stakingKey].sub(tokensToBurn);
                lock.locked = lock.locked.sub(tokensToBurn);
                require(ogToken.burn(tokensToBurn), "OptinoGov: burn failed");
                emit StakeBurnt(tokenOwner, tokensToBurn, lock.stakes[stakingKey], stakingKey);
            }
        }
    }

    // Lock tokens for a duration. If you already locked some tokens, you cannot set a duration that ends before the current one.
    function lock(uint tokens, uint duration) public {
        require(duration <= maxLockTerm, "OptinoGov: Cannot exceed maxLockTerm");
        Lock storage user = locks[msg.sender];

        // TODO: Take into account any staked tokens
        if (user.locked > 0) {
            require(block.timestamp + duration >= user.end, "OptinoGov: duration cannot end before existing stake");

            // Pay rewards until now and reset
            uint elapsed = block.timestamp.sub(user.end.sub(user.duration));
            uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
            rewardPool = rewardPool.sub(reward);
            user.locked = user.locked.add(reward);
            totalVotes = totalVotes.sub(user.votes);
            user.votes = 0;
        }

        // Create stake
        user.locked = user.locked.add(tokens);
        user.duration = duration;
        user.end = block.timestamp.add(duration);
        user.votes = user.locked.mul(duration).div(maxLockTerm);
        totalVotes = totalVotes.add(user.votes);

        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OptinoGov: transferFrom failed");

        emit Locked(msg.sender, tokens, user.locked, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    // TODO
    function collectLockReward() public {
        Lock storage user = locks[msg.sender];
        require(user.locked > 0);

        // Pay rewards until now
        uint elapsed = block.timestamp.sub(user.end.sub(user.duration));
        uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        // BK DEBUG rewardPool = rewardPool.sub(reward);

        if (user.end < block.timestamp) {
            user.end = block.timestamp;
        }
        user.duration = user.end.sub(block.timestamp);
        // BK TEST user.end = user.duration.add(block.timestamp);

        // BK DEBUG require(token.transfer(msg.sender, reward), "OptinoGov: transfer failed");

        emit Collected(msg.sender, elapsed, reward, rewardPool, user.end, user.duration);
    }

    // Unstake all and pay all rewards
    // TODO
    function unlock() public {
        Lock storage user = locks[msg.sender];
        uint tokens = user.locked;
        require(user.locked > 0);
        require(block.timestamp > user.end, "OptinoGov: Staking period not ended yet");

        // Reward
        uint elapsed = block.timestamp.sub(user.end.sub(user.duration));
        uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        rewardPool = rewardPool.sub(reward);
        user.locked = user.locked.add(reward);
        totalVotes = totalVotes.sub(user.votes);
        user.votes = 0;

        uint payout = user.locked;
        user.locked = 0;

        require(ogToken.transfer(msg.sender, payout), "OptinoGov: transfer failed");

        emit Unlocked(msg.sender, payout, tokens, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function propose(string memory description, address[] memory targets, uint[] memory values, bytes[] memory data) public returns(uint) {
        // require(locks[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(10 ** 18), "OptinoGov: Not enough votes to propose");

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.start = block.timestamp;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.targets = targets;
        proposal.values = values;
        proposal.data = data;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.executed = false;

        // Proposal memory proposal = Proposal({
        //     start: block.timestamp,
        //     proposer: msg.sender,
        //     description: description,
        //     targets: [target],
        //     values: [value],
        //     data: [data],
        //     forVotes: 0,
        //     againstVotes: 0,
        //     executed: false
        // });

        // require(token.burnFrom(msg.sender, proposalCost), "OptinoGov: transferFrom failed");

        emit Proposed(msg.sender, proposalCount, description, proposal.targets, proposal.values, proposal.data, block.timestamp);
        return proposalCount;
    }

    // TODO
    function vote(uint oip, bool voteFor) public {
        uint start = proposals[oip].start;
        require(start != 0 && block.timestamp < start.add(votingDuration), "OptinoGov: Voting closed");
        require(!proposals[oip].voted[msg.sender], "OptinoGov: Already voted");
        if (voteFor) {
            proposals[oip].forVotes = proposals[oip].forVotes.add(locks[msg.sender].votes);
        }
        else {
            proposals[oip].againstVotes = proposals[oip].forVotes.add(locks[msg.sender].votes);
        }
        proposals[oip].voted[msg.sender] = true;

        emit Voted(msg.sender, oip, voteFor, proposals[oip].forVotes, proposals[oip].againstVotes);
    }

    function voteWithSignatures(bytes32[] calldata signatures) external {
        // TODO
    }

    function execute(uint oip) public {
        Proposal storage proposal = proposals[oip];
        // require(proposal.start != 0 && block.timestamp >= proposal.start.add(votingDuration).add(executeDelay));

        // if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
        //     return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        // } else {
        //     return 0;
        // }

        // require(proposal.forVotes >= totalVotes.mul(quorum).div(10 ** 18), "OptinoGov: Not enough votes to execute");
        proposal.executed = true;

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success,) = proposal.targets[i].call{value: proposal.values[i]}(proposal.data[i]);
            require(success, "OptinoGov: Execution failed");
        }

        emit Executed(msg.sender, oip);
    }
}
