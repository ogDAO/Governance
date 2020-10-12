pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGTokenInterface.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/OGDTokenInterface.sol";
// import "https://github.com/ogDAO/Governance/blob/master/contracts/SafeMath.sol";

import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./SafeMath.sol";


/// @notice Optino Governance config
contract OptinoGovConfig {
    using SafeMath for uint;

    uint constant SECONDS_PER_YEAR = 10000; // Testing 24 * 60 * 60 * 365;

    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    uint public maxDuration = 10000 seconds; // Testing 365 days;
    uint public rewardsPerSecond = 150_000_000_000_000_000; // 0.15
    uint public collectOnBehalfFee = 5 * 10**16; // 5%, 18 decimals
    uint public collectOnBehalfDelay = 1 seconds; // Testing 7 days
    uint public proposalCost = 100_000_000_000_000_000_000; // 100 tokens assuming 18 decimals
    uint public proposalThreshold = 1 * 10**15; // 0.1%, 18 decimals
    uint public quorum = 2 * 10 ** 17; // 20%, 18 decimals
    uint public quorumDecayPerSecond = 4 * 10**17 / uint(60 * 60 * 24 * 365); // 40% per year, i.e., 0 in 6 months
    uint public votingDuration = 10 seconds; // 3 days;
    uint public executeDelay = 10 seconds; // 2 days;
    uint public rewardPool = 1_000_000 * 10**18;
    uint public totalVotes;

    event MaxDurationUpdated(uint maxDuration);
    event RewardsPerSecondUpdated(uint rewardsPerSecond);
    event CollectOnBehalfFeeUpdated(uint collectOnBehalfFee);
    event CollectOnBehalfDelayUpdated(uint collectOnBehalfDelay);
    event ProposalCostUpdated(uint proposalCost);
    event ProposalThresholdUpdated(uint proposalThreshold);
    event QuorumUpdated(uint quorum);
    event QuorumDecayPerSecondUpdated(uint quorumDecayPerSecond);
    event VotingDurationUpdated(uint votingDuration);
    event ExecuteDelayUpdated(uint executeDelay);

    modifier onlySelf {
        require(msg.sender == address(this), "Not self");
        _;
    }

    constructor(OGTokenInterface _ogToken, OGDTokenInterface _ogdToken) {
        ogToken = _ogToken;
        ogdToken = _ogdToken;
    }
    function setMaxDuration(uint _maxDuration) external onlySelf {
        maxDuration = _maxDuration;
        emit MaxDurationUpdated(maxDuration);
    }
    function setCollectOnBehalfFee(uint _collectOnBehalfFee) external onlySelf {
        collectOnBehalfFee = _collectOnBehalfFee;
        emit CollectOnBehalfFeeUpdated(collectOnBehalfFee);
    }
    function setCollectOnBehalfDelay(uint _collectOnBehalfDelay) external onlySelf {
        collectOnBehalfDelay = _collectOnBehalfDelay;
        emit CollectOnBehalfDelayUpdated(collectOnBehalfDelay);
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
}

/// @notice Optino Governance. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OptinoGov is OptinoGovConfig {
    using SafeMath for uint;

    struct Commitment {
        uint128 duration;
        uint128 end;
        uint tokens;
        uint votes;
        uint staked;
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

    mapping(address => Commitment) public commitments; // Committed tokens per address
    mapping(address => mapping(bytes32 => uint)) stakes;
    mapping(bytes32 => StakeInfo) public stakeInfoData;
    bytes32[] public stakeInfoIndex;
    uint public proposalCount;
    mapping(uint => Proposal) public proposals;

    event Committed(address indexed user, uint tokens, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event StakeInfoAdded(bytes32 stakingKey, uint dataType, address[4] addresses, uint[6] uints, string string0, string string1, string string2, string string3);
    event Staked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event Unstaked(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event StakeBurnt(address tokenOwner, uint tokens, uint balance, bytes32 stakingKey);
    event Collected(address indexed user, uint elapsed, uint reward, uint rewardPool, uint end, uint duration);
    event Uncommitted(address indexed user, uint amount, uint balance, uint duration, uint end, uint votes, uint rewardPool, uint totalVotes);
    event Proposed(address indexed proposer, uint oip, string description, address[] targets, uint[] value, bytes[] data, uint start);
    event Voted(address indexed user, uint oip, bool voteFor, uint forVotes, uint againstVotes);
    event Executed(address indexed user, uint oip);

    constructor(OGTokenInterface _ogToken, OGDTokenInterface _ogdToken) OptinoGovConfig(_ogToken, _ogdToken) {
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
        Commitment storage committment = commitments[msg.sender];
        require(committment.tokens > 0, "OptinoGov: Commit before staking");
        require(committment.tokens >= committment.staked + tokens, "OptinoGov: Insufficient tokens to stake");
        committment.staked = committment.staked.add(tokens);
        // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].add(tokens);
        // TODO emit Staked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
    }
    function _subStake(uint tokens, bytes32 stakingKey) internal {
        Commitment storage committment = commitments[msg.sender];
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
        Commitment storage committment = commitments[tokenOwner];
        // TODO _staked = committment.stakes[stakingKey];
    }

    function burnStake(address[] calldata tokenOwners, bytes32 stakingKey, uint percent) external onlySelf {
        for (uint i = 0; i < tokenOwners.length; i++) {
            address tokenOwner = tokenOwners[i];
            Commitment storage committment = commitments[tokenOwner];
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

    // Commit tokens for some duration. If you already committed some tokens, you cannot set a duration that ends before the current one
    function commit(uint tokens, uint duration) public {
        require(duration <= maxDuration, "Cannot exceed maxDuration");
        Commitment storage user = commitments[msg.sender];

        // TODO: Take into account any staked tokens
        if (user.tokens > 0) {
            require(block.timestamp + duration >= user.end, "duration cannot end before existing commitment period");

            // Pay rewards until now and reset
            uint elapsed = block.timestamp.sub(uint(user.end).sub(user.duration));
            uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
            rewardPool = rewardPool.sub(reward);
            user.tokens = user.tokens.add(reward);
            totalVotes = totalVotes.sub(user.votes);
            user.votes = 0;
        }

        // Create stake
        user.tokens = user.tokens.add(tokens);
        user.duration = uint128(duration);
        user.end = uint128(block.timestamp.add(duration));
        user.votes = user.tokens.mul(duration).div(SECONDS_PER_YEAR);
        totalVotes = totalVotes.add(user.votes);

        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        require(ogdToken.mint(msg.sender, tokens), "OGD mint failed");

        emit Committed(msg.sender, tokens, user.tokens, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function collectRewardFor(address tokenOwner) public {
        _collectReward(tokenOwner, false, 0);
    }
    function collectReward(bool commitRewards, uint duration) public {
        _collectReward(msg.sender, commitRewards, duration);
    }
    function _collectReward(address tokenOwner, bool commitRewards, uint duration) internal {
        Commitment storage user = commitments[tokenOwner];
        require(user.tokens > 0);

        // Pay rewards for period = now - beginning = now - (end - duration)
        uint elapsed = block.timestamp.sub(uint(user.end).sub(user.duration));
        uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        if (reward > rewardPool) {
            reward = rewardPool;
        }
        if (reward > 0) {
            uint callerReward = 0;
            rewardPool = rewardPool.sub(reward);
            if (msg.sender != tokenOwner) {
                require(user.end + collectOnBehalfDelay < block.timestamp, "Commitment not ended");
                callerReward = reward.mul(collectOnBehalfFee).div(10 ** 18);
                reward = reward.sub(callerReward);
            }
            if (commitRewards) {
                user.tokens = user.tokens.add(reward);
                if (user.end < block.timestamp) {
                    user.end = uint128(block.timestamp);
                }
                if (duration > 0) {
                    require(duration <= maxDuration, "Cannot exceed maxDuration");
                    user.duration = uint128(duration);
                    user.end = uint128(block.timestamp.add(duration));
                    totalVotes = totalVotes.sub(user.votes);
                    user.votes = user.tokens.mul(user.duration).div(SECONDS_PER_YEAR);
                    totalVotes = totalVotes.add(user.votes);
                } else {
                    user.duration = uint128(uint(user.end).sub(block.timestamp));
                    // NOTE - Voting left as proportion of the original duration
                }
                require(ogToken.mint(address(this), reward), "reward OG mint failed");
                require(ogdToken.mint(msg.sender, reward), "reward OGD mint failed");
            } else {
                user.duration = uint(user.end) <= block.timestamp ? 0 : uint128(uint(user.end).sub(block.timestamp));
                totalVotes = totalVotes.sub(user.votes);
                user.votes = user.tokens.mul(user.duration).div(SECONDS_PER_YEAR);
                totalVotes = totalVotes.add(user.votes);
                require(ogToken.mint(tokenOwner, reward), "reward OG mint failed");
            }
            if (callerReward > 0) {
                require(ogToken.mint(msg.sender, callerReward), "callerReward OG mint failed");
            }
        }
        emit Collected(msg.sender, elapsed, reward, rewardPool, user.end, user.duration);
    }

    // Unstake all and pay all rewards
    // TODO
    function uncommit() public {
        Commitment storage user = commitments[msg.sender];
        uint tokens = user.tokens;
        require(user.tokens > 0);
        require(block.timestamp > user.end, "OptinoGov: Commitment period not ended yet");

        // Reward
        uint elapsed = block.timestamp.sub(uint(user.end).sub(user.duration));
        uint reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        rewardPool = rewardPool.sub(reward);
        user.tokens = user.tokens.add(reward);
        totalVotes = totalVotes.sub(user.votes);
        user.votes = 0;

        uint payout = user.tokens;
        user.tokens = 0;

        require(ogToken.transfer(msg.sender, payout), "OptinoGov: transfer failed");

        emit Uncommitted(msg.sender, payout, tokens, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function propose(string memory description, address[] memory targets, uint[] memory values, bytes[] memory data) public returns(uint) {
        // require(commitments[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(10 ** 18), "OptinoGov: Not enough votes to propose");

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
            proposals[oip].forVotes = proposals[oip].forVotes.add(commitments[msg.sender].votes);
        }
        else {
            proposals[oip].againstVotes = proposals[oip].forVotes.add(commitments[msg.sender].votes);
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
