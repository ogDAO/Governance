// From https://github.com/bartjman/XS2Option/blob/master/contracts/XS2Gov.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: Overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "SafeMath: Underflow"); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
        { if (a == 0) {return 0;} uint256 c = a * b; require(c / a == b, "SafeMath: Overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: Div by 0"); uint256 c = a / b; return c; }
}

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

struct Stake {
    uint256 duration;
    uint256 end;
    uint256 amount;
    uint256 votes;
}

struct Proposal {
    uint256 start;
    address proposer;
    string description; // Use an IPFS link to JSON data - OK
    address[] targets;
    bytes[] data;

    uint256 forVotes;
    uint256 againstVotes;
    mapping(address => bool) voted;

    bool executed;
}

contract OptinoGov {
    using SafeMath for uint256;

    // Design parameters
    // Lowish gas
    // No entanglement with other parts of the system (stand alone)
    // Timelock built into this contract, no need for a separate one
    address public token;
    uint256 public rewardsPerSecond;

    uint256 public proposalCost;
    uint256 public proposalThreshold;
    uint256 public quorum;
    uint256 public votingDuration;
    uint256 public executeDelay;

    uint256 public rewardPool;
    uint256 public totalVotes;
    mapping(address => Stake) public stakes; // Staked tokens per address

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event Staked(address indexed user, uint256 amount, uint256 balance, uint256 duration, uint256 end, uint256 votes, uint256 rewardPool, uint256 totalVotes);
    event Collected(address indexed user, uint256 elapsed, uint256 reward, uint256 rewardPool, uint256 end, uint256 duration);
    event Unstaked(address indexed user, uint256 amount, uint256 balance, uint256 duration, uint256 end, uint256 votes, uint256 rewardPool, uint256 totalVotes);
    event Proposed(address indexed proposer, uint256 oip, string description, address[] targets, bytes[] data, uint256 start);
    event Voted(address indexed user, uint256 oip, bool voteFor, uint256 forVotes, uint256 againstVotes);
    event Executed(address indexed user, uint256 oip);


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

    // Stake tokens and set a duration. If you already have a stake you cannot set a duration that ends before the current one.
    function stake(uint256 amount, uint256 duration) public {
        require(duration < 365 days, "OptinoGov: Maximum duration is 1 year");
        Stake memory user = stakes[msg.sender];

        if (user.amount > 0) {
            require(block.timestamp + duration > user.end, "OptinoGov: duration cannot end before existing stake");

            // Pay rewards until now and reset
            uint256 elapsed = block.timestamp.sub(user.end.sub(user.duration));
            uint256 reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
            rewardPool = rewardPool.sub(reward);
            user.amount = user.amount.add(reward);
            totalVotes = totalVotes.sub(user.votes);
            user.votes = 0;
        }

        // Create stake
        user.amount = user.amount.add(amount);
        user.duration = duration;
        user.end = block.timestamp.add(duration);
        user.votes = user.amount.mul(duration).div(365 days);
        totalVotes = totalVotes.add(user.votes);

        stakes[msg.sender] = user;

        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "OptinoGov: transferFrom failed");

        emit Staked(msg.sender, amount, user.amount, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function collect() public {
        Stake memory user = stakes[msg.sender];
        require(user.amount > 0);

        // Pay rewards until now
        uint256 elapsed = block.timestamp.sub(user.end.sub(user.duration));
        uint256 reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        rewardPool = rewardPool.sub(reward);

        if (user.end < block.timestamp) {
            user.end = block.timestamp;
        }
        user.duration = user.end.sub(block.timestamp);

        require(ERC20(token).transfer(msg.sender, reward), "OptinoGov: transfer failed");

        emit Collected(msg.sender, elapsed, reward, rewardPool, user.end, user.duration);
    }

    // Unstake all and pay all rewards
    function unstake() public {
        Stake memory user = stakes[msg.sender];
        require(user.amount > 0);
        require(block.timestamp > user.end, "OptinoGov: Staking period not ended yet");

        // Reward
        uint256 elapsed = block.timestamp.sub(user.end.sub(user.duration));
        uint256 reward = elapsed.mul(rewardsPerSecond).mul(user.votes).div(totalVotes);
        rewardPool = rewardPool.sub(reward);
        user.amount = user.amount.add(reward);
        totalVotes = totalVotes.sub(user.votes);
        user.votes = 0;

        uint256 payout = user.amount;
        user.amount = 0;

        stakes[msg.sender] = user;

        require(ERC20(token).transfer(msg.sender, payout), "OptinoGov: transfer failed");

        emit Unstaked(msg.sender, payout, user.amount, user.duration, user.end, user.votes, rewardPool, totalVotes);
    }

    function propose(string memory description, address[] memory targets, bytes[] memory data) public returns(uint256) {
        require(stakes[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(1e6), "OptinoGov: Not enough votes to propose");

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

    function vote(uint256 oip, bool voteFor) public {
        uint256 start = proposals[oip].start;
        require(start != 0 && block.timestamp < start.add(votingDuration), "OptinoGov: Voting closed");
        require(!proposals[oip].voted[msg.sender], "OptinoGov: Already voted");
        if (voteFor) {
            proposals[oip].forVotes = proposals[oip].forVotes.add(stakes[msg.sender].votes);
        }
        else {
            proposals[oip].againstVotes = proposals[oip].forVotes.add(stakes[msg.sender].votes);
        }
        proposals[oip].voted[msg.sender] = true;

        emit Voted(msg.sender, oip, voteFor, proposals[oip].forVotes, proposals[oip].againstVotes);
    }

    function execute(uint256 oip) public {
        Proposal storage proposal = proposals[oip];
        require(proposal.start != 0 && block.timestamp < proposal.start.add(votingDuration).add(executeDelay));
        require(proposal.forVotes >= totalVotes.mul(quorum).div(1e6), "OptinoGov: Not enough votes to execute");
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success,) = proposal.targets[i].call(proposal.data[i]);
            require(success, "OptinoGov: Execution failed");
        }

        emit Executed(msg.sender, oip);
    }
}
