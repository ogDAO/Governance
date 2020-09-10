// ----------------------------------------------------------------------------
// Optino Governance
//
// Originally based on https://github.com/bartjman/XS2Option/blob/master/contracts/XS2Gov.sol (MIT)
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: GPLv2
// ----------------------------------------------------------------------------
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


// import "SafeMath.sol";
/// @notice Safe maths
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


/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}


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

    // Token
    // - dataType 1
    // - address tokenAddress
    // Feed
    // - dataType 2
    // - address feedAddress
    // - uint feedType
    // - uint feedDecimals
    // - string name
    // Conventions
    // - dataType 3
    // - address [token0, token1];
    // - address [feed0, feed1]
    // - uint[6] [type0, type1, decimals0, decimals1, inverse0, inverse1]
    // - string [feed0Name, feedName2, Market, Convention]
    // General
    // - dataType 4
    // - address[4] addresses;
    // - address [feed0, feed1]
    // - uint[6] uints;
    // - string[4] strings;
    struct StakeInfo {
        uint dataType;
        address[4] addresses;
        uint[6] uints;
        string[4] strings;
    }

    struct Proposal {
        uint start;
        address proposer;
        string description; // Use an IPFS link to JSON data - OK
        address[] targets;
        bytes[] data;

        uint forVotes;
        uint againstVotes;
        mapping(address => bool) voted;

        bool executed;
    }

    // Design parameters
    // Lowish gas
    // No entanglement with other parts of the system (stand alone)
    // Timelock built into this contract, no need for a separate one
    address public token;
    uint public rewardsPerSecond;

    uint public proposalCost;
    uint public proposalThreshold;
    uint public quorum;
    uint public votingDuration;
    uint public executeDelay;

    uint public rewardPool;
    uint public totalVotes;
    mapping(address => Lock) public locks; // Locked tokens per address
    mapping(bytes32 => StakeInfo) public stakeInfoData;
    bytes32[] public stakeInfoIndex;

    uint public proposalCount;
    mapping(uint => Proposal) public proposals;

    event RewardsPerSecondUpdated(uint rewardsPerSecond);
    event ProposalCostUpdated(uint proposalCost);
    event ProposalThresholdUpdated(uint proposalThreshold);
    event QuorumUpdated(uint quorum);
    event VotingDurationUpdated(uint votingDuration);
    event ExecuteDelayUpdated(uint executeDelay);

    event Staked(address indexed user, uint amount, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event Collected(address indexed user, uint elapsed, uint reward, uint rewardPool, uint end, uint duration);
    event Unstaked(address indexed user, uint amount, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event Proposed(address indexed proposer, uint oip, string description, address[] targets, bytes[] data, uint start);
    event Voted(address indexed user, uint oip, bool voteFor, uint forVotes, uint againstVotes);
    event Executed(address indexed user, uint oip);


    modifier onlySelf {
        require(msg.sender == address(this), "Not self");
        _;
    }


    constructor(address token_) {
        token = token_;
        // TODO: Parameterise these variables, allowing calls back to this smart contract to update via proposals
        // Total reward pool = 5.000.000 * 10^18
        // Total rewards per second = 1.5 * 10^17
        // Your reward per second is votes/totalVotes * rewards per second
        // Your reward is elapsed time * rewards per second * votes / totalVotes
        rewardsPerSecond = 150000000000000000;
        proposalCost = 100000000000000000000; // 100 tokens
        proposalThreshold = 100; // 6 decimals, so this is 0.1%
        quorum = 200000; // 6 decimals, so this is 20%
        votingDuration = 3 hours; // 3 days;
        executeDelay = 2 hours; // 2 days;
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
    function setVotingDuration(uint _votingDuration) external onlySelf {
        votingDuration = _votingDuration;
        emit VotingDurationUpdated(votingDuration);
    }
    function setExecuteDelay(uint _executeDelay) external onlySelf {
        executeDelay = _executeDelay;
        emit ExecuteDelayUpdated(executeDelay);
    }

    function addStakeForToken(uint tokens, address tokenAddress) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress));
        StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
        if (stakeInfo.dataType == 0) {
            stakeInfoData[stakingKey] = StakeInfo(1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], ["", "", "", ""]);
            stakeInfoIndex.push(stakingKey);
        }
        _addStake(tokens, stakingKey);
    }
    function subStakeForToken(uint tokens, address tokenAddress) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress));
        _subStake(tokens, stakingKey);
    }
    function addStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
        StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
        if (stakeInfo.dataType == 0) {
            stakeInfoData[stakingKey] = StakeInfo(2, [feedAddress, address(0), address(0), address(0)], [uint(feedType), uint(feedDecimals), uint(0), uint(0), uint(0), uint(0)], [name, "", "", ""]);
            stakeInfoIndex.push(stakingKey);
        }
        _addStake(tokens, stakingKey);
    }
    function subStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
        _subStake(tokens, stakingKey);
    }
    function addStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory stringsz) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, stringsz[0], stringsz[1], stringsz[2], stringsz[3]));
        StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
        if (stakeInfo.dataType == 0) {
            stakeInfoData[stakingKey] = StakeInfo(3, addresses, uints, stringsz);
            stakeInfoIndex.push(stakingKey);
        }
        _addStake(tokens, stakingKey);
    }
    function subStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory stringsz) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, stringsz[0], stringsz[1], stringsz[2], stringsz[3]));
        _subStake(tokens, stakingKey);
    }
    function addStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory stringsz) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, stringsz[0], stringsz[1], stringsz[2], stringsz[3]));
        StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
        if (stakeInfo.dataType == 0) {
            stakeInfoData[stakingKey] = StakeInfo(dataType, addresses, uints, stringsz);
            stakeInfoIndex.push(stakingKey);
        }
        _addStake(tokens, stakingKey);
    }
    function subStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory stringsz) external {
        bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, stringsz[0], stringsz[1], stringsz[2], stringsz[3]));
        _subStake(tokens, stakingKey);
    }
    function _addStake(uint tokens, bytes32 stakingKey) internal {
        Lock storage lock = locks[msg.sender];
        require(lock.locked > 0, "Lock tokens before staking");
        require(lock.locked >= lock.staked + tokens, "Insufficient tokens to stake");
        lock.staked = lock.staked.add(tokens);
        lock.stakes[stakingKey] = lock.stakes[stakingKey].add(tokens);
    }
    function _subStake(uint tokens, bytes32 stakingKey) internal {
        Lock storage lock = locks[msg.sender];
        require(lock.locked > 0, "Lock and stake tokens before unstaking");
        require(lock.stakes[stakingKey] >= tokens, "Insufficient staked tokens");
        lock.staked = lock.staked.sub(tokens);
        lock.stakes[stakingKey] = lock.stakes[stakingKey].sub(tokens);
    }

    // Stake tokens and set a duration. If you already have a stake you cannot set a duration that ends before the current one.
    function lock(uint amount, uint duration) public {
        require(duration <= 365 days, "OptinoGov: Maximum duration is 1 year");
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
        user.locked = user.locked.add(amount);
        user.duration = duration;
        user.end = block.timestamp.add(duration);
        user.votes = user.locked.mul(duration).div(365 days);
        totalVotes = totalVotes.add(user.votes);

        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "OptinoGov: transferFrom failed");

        emit Staked(msg.sender, amount, user.locked, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

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

        // BK DEBUG require(ERC20(token).transfer(msg.sender, reward), "OptinoGov: transfer failed");

        emit Collected(msg.sender, elapsed, reward, rewardPool, user.end, user.duration);
    }

    // Unstake all and pay all rewards
    function unlock() public {
        Lock storage user = locks[msg.sender];
        uint amount = user.locked;
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

        require(ERC20(token).transfer(msg.sender, payout), "OptinoGov: transfer failed");

        emit Unstaked(msg.sender, payout, amount, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function propose(string memory description, address[] memory targets, bytes[] memory data) public returns(uint) {
        require(locks[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(1e6), "OptinoGov: Not enough votes to propose");

        proposalCount++;

        proposals[proposalCount].start = block.timestamp;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].description = description;
        proposals[proposalCount].targets = targets;
        proposals[proposalCount].data = data;

        require(ERC20(token).transferFrom(msg.sender, address(this), proposalCost), "OptinoGov: transferFrom failed");

        emit Proposed(msg.sender, proposalCount, description, targets, data, block.timestamp);
        return proposalCount;
    }

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
        require(proposal.start != 0 && block.timestamp >= proposal.start.add(votingDuration).add(executeDelay));
        require(proposal.forVotes >= totalVotes.mul(quorum).div(1e6), "OptinoGov: Not enough votes to execute");
        proposal.executed = true;

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success,) = proposal.targets[i].call(proposal.data[i]);
            require(success, "OptinoGov: Execution failed");
        }

        emit Executed(msg.sender, oip);
    }
}
