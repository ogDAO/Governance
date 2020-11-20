pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./SafeMath.sol";
import "./InterestUtils.sol";
import "./CurveInterface.sol";

/// @notice Optino Governance config
contract OptinoGovBase {
    using SafeMath for uint;

    bytes32 private constant KEY_OGTOKEN = keccak256(abi.encodePacked("ogToken"));
    bytes32 private constant KEY_OGDTOKEN = keccak256(abi.encodePacked("ogdToken"));
    bytes32 private constant KEY_OGREWARDCURVE = keccak256(abi.encodePacked("ogRewardCurve"));
    bytes32 private constant KEY_VOTEWEIGHTCURVE = keccak256(abi.encodePacked("voteWeightCurve"));
    bytes32 private constant KEY_MAXDURATION = keccak256(abi.encodePacked("maxDuration"));
    bytes32 private constant KEY_COLLECTREWARDFORFEE = keccak256(abi.encodePacked("collectRewardForFee"));
    bytes32 private constant KEY_COLLECTREWARDFORDELAY = keccak256(abi.encodePacked("collectRewardForDelay"));
    bytes32 private constant KEY_PROPOSALCOST = keccak256(abi.encodePacked("proposalCost"));
    bytes32 private constant KEY_PROPOSALTHRESHOLD = keccak256(abi.encodePacked("proposalThreshold"));
    bytes32 private constant KEY_QUORUM = keccak256(abi.encodePacked("quorum"));
    bytes32 private constant KEY_QUORUMDECAYPERSECOND = keccak256(abi.encodePacked("quorumDecayPerSecond"));
    bytes32 private constant KEY_VOTINGDURATION = keccak256(abi.encodePacked("votingDuration"));
    bytes32 private constant KEY_EXECUTEDELAY = keccak256(abi.encodePacked("executeDelay"));

    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public ogRewardCurve;
    CurveInterface public voteWeightCurve;
    uint public maxDuration = 10000 seconds; // Testing 365 days;
    uint public collectRewardForFee = 5e16; // 5%, 18 decimals
    uint public collectRewardForDelay = 1 seconds; // Testing 7 days
    uint public proposalCost = 100e18; // 100 tokens assuming 18 decimals
    uint public proposalThreshold = 1e15; // 0.1%, 18 decimals
    uint public quorum = 2e17; // 20%, 18 decimals
    uint public quorumDecayPerSecond = 4e17 / uint(365 days); // 40% per year, i.e., 0 in 6 months
    uint public votingDuration = 10 seconds; // 3 days;
    uint public executeDelay = 10 seconds; // 2 days;

    event ConfigUpdated(string key, uint value);

    modifier onlySelf {
        require(msg.sender == address(this), "Not self");
        _;
    }

    constructor(OGTokenInterface _ogToken, OGDTokenInterface _ogdToken, CurveInterface _ogRewardCurve, CurveInterface _voteWeightCurve) {
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        ogRewardCurve = _ogRewardCurve;
        voteWeightCurve = _voteWeightCurve;
    }

    function setConfig(string memory key, uint value) external onlySelf {
        bytes32 _key = keccak256(abi.encodePacked(key));
        if (_key == KEY_OGTOKEN) {
            ogToken = OGTokenInterface(address(value));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            ogdToken = OGDTokenInterface(address(value));
        } else if (_key == KEY_OGREWARDCURVE) {
            ogRewardCurve = CurveInterface(address(value));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            voteWeightCurve = CurveInterface(address(value));
        } else if (_key == KEY_MAXDURATION) {
            require(maxDuration < 5 * 365 days, "Cannot exceed 5 years");
            maxDuration = value;
        } else if (_key == KEY_COLLECTREWARDFORFEE) {
            require(collectRewardForFee < 1e18, "Cannot exceed 100%");
            collectRewardForFee = value;
        } else if (_key == KEY_COLLECTREWARDFORDELAY) {
            collectRewardForDelay = value;
        } else if (_key == KEY_PROPOSALCOST) {
            proposalCost = value;
        } else if (_key == KEY_PROPOSALTHRESHOLD) {
            proposalThreshold = value;
        } else if (_key == KEY_QUORUM) {
            quorum = value;
        } else if (_key == KEY_QUORUMDECAYPERSECOND) {
            quorumDecayPerSecond = value;
        } else if (_key == KEY_VOTINGDURATION) {
            votingDuration = value;
        } else if (_key == KEY_EXECUTEDELAY) {
            executeDelay = value;
        } else {
            revert("Invalid key");
        }
        emit ConfigUpdated(key, value);
    }


    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes memory sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

/// @notice Optino Governance. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OptinoGov is ERC20, OptinoGovBase, InterestUtils {
    using SafeMath for uint;

    struct Account {
        uint64 duration;
        uint64 end;
        uint64 lastDelegated;
        uint64 lastVoted;
        uint64 index;
        address delegatee;
        uint rate; // max uint64 = 18_446744073_709551615 = 1800%
        uint balance;
        uint votes;
        uint delegatedVotes;
    }
    struct Proposal {
        uint64 start;
        uint32 executed;
        address proposer;
        string description;
        address[] targets;
        uint[] values;
        bytes[] data;
        uint forVotes;
        uint againstVotes;
    }

    string private constant NAME = "OptinoGov";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 private constant EIP712_VOTE_TYPEHASH = keccak256("Vote(uint256 id,bool support)");
    bytes32 private immutable EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this)));

    uint private _totalSupply;
    mapping(address => Account) private accounts;
    address[] public accountsIndex;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalVotes;

    Proposal[] private proposals;
    mapping(uint => mapping(address => bool)) public voted;

    event DelegateUpdated(address indexed oldDelegatee, address indexed delegatee, uint votes);
    event Committed(address indexed user, uint tokens, uint balance, uint duration, uint end, address delegatee, uint votes, uint totalVotes);
    event Collected(address indexed user, uint elapsed, uint reward, uint callerReward, uint end, uint duration);
    event Uncommitted(address indexed user, uint tokens, uint balance, uint duration, uint end, uint votes, uint totalVotes);
    event Proposed(address indexed proposer, uint id, string description, address[] targets, uint[] value, bytes[] data, uint start);
    event Voted(address indexed user, uint id, bool support, uint votes, uint forVotes, uint againstVotes);
    event Executed(address indexed user, uint id);

    constructor(OGTokenInterface ogToken, OGDTokenInterface ogdToken, CurveInterface ogRewardCurve, CurveInterface voteWeightCurve) OptinoGovBase(ogToken, ogdToken, ogRewardCurve, voteWeightCurve) {
    }

    function symbol() override external pure returns (string memory) {
        return NAME;
    }
    function name() override external pure returns (string memory) {
        return NAME;
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
    function transfer(address /*to*/, uint /*tokens*/) override external returns (bool success) {
        require(false, "Unimplemented");
        _totalSupply = _totalSupply;
        return true;
    }
    function approve(address /*spender*/, uint /*tokens*/) override external returns (bool success) {
        require(false, "Unimplemented");
        _totalSupply = _totalSupply;
        return true;
    }
    function transferFrom(address /*from*/, address /*to*/, uint /*tokens*/) override external returns (bool success) {
        require(false, "Unimplemented");
        _totalSupply = _totalSupply;
        return true;
    }
    function allowance(address /*tokenOwner*/, address /*spender*/) override external pure returns (uint remaining) {
        return 0;
    }

    function getAccountByIndex(uint i) public view returns (address tokenOwner, Account memory account) {
        require(i < accountsIndex.length, "Invalid index");
        tokenOwner = accountsIndex[i];
        account = accounts[tokenOwner];
    }
    function accountsLength() public view returns (uint) {
        return accountsIndex.length;
    }

    function delegate(address delegatee) public {
        require(delegatee == address(0) || accounts[delegatee].end != 0, "delegatee not registered");
        require(msg.sender != delegatee, "Cannot delegate to self");
        Account storage account = accounts[msg.sender];
        require(uint(account.lastVoted) + votingDuration < block.timestamp, "Cannot delegate after recent vote");
        require(uint(account.lastDelegated) + votingDuration < block.timestamp, "Cannot vote after recent delegation");
        address oldDelegatee = account.delegatee;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes = accounts[account.delegatee].delegatedVotes.sub(account.votes);
        }
        account.delegatee = delegatee;
        account.lastDelegated = uint64(block.timestamp);
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes = accounts[account.delegatee].delegatedVotes.add(account.votes);
        }
        emit DelegateUpdated(oldDelegatee, delegatee, account.votes);
    }

    function updateStatsBefore(Account storage account) internal {
        totalVotes = totalVotes.sub(account.votes);
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes = accounts[account.delegatee].delegatedVotes.sub(account.votes);
        }
    }
    function updateStatsAfter(Account storage account) internal {
        uint rate = voteWeightCurve.getRate(uint(account.duration));
        account.votes = account.balance.mul(rate).div(1e18);
        totalVotes = totalVotes.add(account.votes);
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes = accounts[account.delegatee].delegatedVotes.add(account.votes);
        }
    }

    function accruedReward(address tokenOwner) public view returns (uint _reward, uint _term) {
        return _calculateReward(accounts[tokenOwner]);
    }
    function _calculateReward(Account memory account) internal view returns (uint _reward, uint _term) {
        uint from = account.end == 0 ? block.timestamp : uint(account.end).sub(uint(account.duration));
        uint futureValue = InterestUtils.futureValue(account.balance, from, block.timestamp, account.rate);
        _reward = futureValue.sub(account.balance);
        _term = block.timestamp.sub(from);
    }
    function _getOGRewardRate(uint term) internal view returns (uint rate) {
        try ogRewardCurve.getRate(term) returns (uint _rate) {
            rate = _rate;
        } catch {
            rate = 0;
        }
    }

    function _changeCommitment(address tokenOwner, uint depositTokens, uint withdrawTokens, bool withdrawRewards, uint duration) internal {
        Account storage account = accounts[tokenOwner];
        if (depositTokens > 0) {
            require(duration > 0, "Duration must be > 0");
        }
        if (withdrawTokens > 0) {
            require(uint(account.end) < block.timestamp, "Commitment still active");
            require(withdrawTokens <= account.balance, "Unsufficient balance");
        }
        updateStatsBefore(account);
        (uint reward, /*uint term*/) = _calculateReward(account);
        uint availableToMint = ogToken.availableToMint();
        if (reward > availableToMint) {
            reward = availableToMint;
        }
        if (reward > 0) {
            if (withdrawRewards) {
                require(ogToken.mint(tokenOwner, reward), "OG mint failed");
            } else {
                if (msg.sender != tokenOwner) {
                    uint callerReward = reward.mul(collectRewardForFee).div(1e18);
                    if (callerReward > 0) {
                        reward = reward.sub(callerReward);
                        require(ogToken.mint(msg.sender, callerReward), "OG mint failed");
                    }
                }
                require(ogToken.mint(address(this), reward), "OG mint failed");
                account.balance = account.balance.add(reward);
                _totalSupply = _totalSupply.add(reward);
                require(ogdToken.mint(tokenOwner, reward), "OGD mint failed");
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if (depositTokens == 0 && withdrawTokens == 0) {
            // require(block.timestamp + duration >= account.end, "Cannot shorten duration");
            // TODO emit Recommit
            account.duration = uint64(duration);
            account.end = uint64(block.timestamp.add(duration));
        }
        if (depositTokens > 0) {
            if (account.end == 0) {
                uint rate = _getOGRewardRate(duration);
                accounts[tokenOwner] = Account(uint64(duration), uint64(block.timestamp.add(duration)), uint64(0), uint64(0), uint64(accountsIndex.length), address(0), rate, depositTokens, 0, 0);
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
            } else {
                require(block.timestamp + duration >= account.end, "Cannot shorten duration");
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp.add(duration));
                account.rate = _getOGRewardRate(duration);
                account.balance = account.balance.add(depositTokens);
            }
            require(ogdToken.mint(tokenOwner, depositTokens), "OGD mint failed");
            // TODO account.votes not updated. remove remaining variables
            emit Committed(tokenOwner, depositTokens, account.balance, account.duration, account.end, account.delegatee, account.votes, totalVotes);
            _totalSupply = _totalSupply.add(depositTokens);
            emit Transfer(address(0), tokenOwner, depositTokens);
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
            // TODO: Check
            account.duration = uint64(0);
            account.end = uint64(block.timestamp);
            require(ogdToken.withdrawDividendsAndBurnFor(tokenOwner, withdrawTokens), "OG withdrawDividendsAndBurnFor failed");
            require(ogToken.transfer(tokenOwner, withdrawTokens), "OG transfer failed");
            // TODO Uncommit
        //     emit Unstaked(msg.sender, withdrawTokens, reward, tokensWithSlashingFactor, rewardWithSlashingFactor);
        }
        updateStatsAfter(account);
    }
    function commit(uint tokens, uint duration) public {
        require(duration > 0, "duration must be > 0");
        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        _changeCommitment(msg.sender, tokens, 0, false, duration);
    }
    function uncommit(uint tokens) public {
        if (tokens == 0) {
            tokens = accounts[msg.sender].balance;
            uint ogdTokens = ogdToken.balanceOf(msg.sender);
            if (ogdTokens < tokens) {
                tokens = ogdTokens;
            }
        }
        require(accounts[msg.sender].balance > 0, "No balance to uncommit");
        _changeCommitment(msg.sender, 0, tokens, tokens == accounts[msg.sender].balance, 0);
        emit Transfer(msg.sender, address(0), tokens);
    }
    function uncommitFor(address tokenOwner) public {
        require(accounts[tokenOwner].balance > 0, "tokenOwner has no balance to tidy");
        _changeCommitment(tokenOwner, 0, 0, false, 0);
    }


    function propose(string memory description, address[] memory targets, uint[] memory values, bytes[] memory data) public returns(uint) {
        console.log("        > %s -> propose(description %s)", msg.sender, description);
        // require(accounts[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(1e18), "OptinoGov: Not enough votes to propose");

        require(targets.length > 0 && values.length == targets.length && data.length == targets.length, "Invalid data");

        Proposal storage proposal = proposals.push();
        // proposalCount++;
        // Proposal storage proposal = proposals[proposalCount];
        proposal.start = uint64(block.timestamp);
        // proposal.executed = 0;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.targets = targets;
        proposal.values = values;
        proposal.data = data;
        // proposal.forVotes = 0;
        // proposal.againstVotes = 0;

        // Proposal memory proposal = Proposal({
        //     start: block.timestamp,
        //     proposer: msg.sender,
        //     description: description,
        //     targets: targets,
        //     values: values,
        //     data: data,
        //     forVotes: 0,
        //     againstVotes: 0,
        //     executed: 0
        // });
        // proposals.push(proposal);

        // require(token.burnFrom(msg.sender, proposalCost), "OptinoGov: transferFrom failed");

        emit Proposed(msg.sender, proposals.length - 1, description, proposal.targets, proposal.values, proposal.data, block.timestamp);
        return proposals.length - 1;
    }
    function getProposal(uint i) public view returns (uint64 start, uint32 executed, address proposer, string memory description, address[] memory targets, uint[] memory _values, bytes[] memory data, uint forVotes, uint againstVotes) {
        require(i < proposals.length, "Invalid index");
        Proposal memory proposal = proposals[i];
        return (proposal.start, proposal.executed, proposal.proposer, proposal.description, proposal.targets, proposal.values, proposal.data, proposal.forVotes, proposal.againstVotes);
    }
    function proposalsLength() public view returns (uint) {
        return proposals.length;
    }

    function vote(uint id, bool support) public {
        _vote(msg.sender, id, support);
    }
    function _vote(address voter, uint id, bool support) internal {
        Proposal storage proposal = proposals[id];
        require(proposal.start != 0 && block.timestamp < uint(proposal.start).add(votingDuration), "Voting closed");
        require(accounts[voter].lastDelegated + votingDuration < block.timestamp, "Cannot vote after recent delegation");
        require(!voted[id][voter], "Already voted");
        uint votes = accounts[voter].votes + accounts[voter].delegatedVotes;
        if (accounts[voter].delegatee != address(0)) {
            if (support) {
                proposal.forVotes = proposal.forVotes.add(votes);
            } else {
                proposal.againstVotes = proposal.forVotes.add(votes);
            }
        }
        voted[id][voter] = true;
        accounts[voter].lastVoted = uint64(block.timestamp);
        emit Voted(voter, id, support, votes, proposal.forVotes, proposal.againstVotes);
    }
    function voteDigest(uint id, bool support) public view returns (bytes32 digest) {
        // bytes32 domainSeparator = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(EIP712_VOTE_TYPEHASH, id, support));
        digest = keccak256(abi.encodePacked("\x19\x01", EIP712_DOMAIN_SEPARATOR, structHash));
    }
    function voteBySigs(uint id, bytes[] memory sigs) public {
        for (uint i = 0; i < sigs.length; i++) {
            bytes memory sig = sigs[i];
            bytes32 digest = voteDigest(id, true);
            address voter = ecrecoverFromSig(digest, sig);
            if (voter != address(0) && accounts[voter].balance > 0) {
                if (!voted[id][voter]) {
                    _vote(voter, id, true);
                }
            } else {
                digest = voteDigest(id, false);
                voter = ecrecoverFromSig(digest, sig);
                if (voter != address(0) && accounts[voter].balance > 0) {
                    if (!voted[id][voter]) {
                        _vote(voter, id, false);
                    }
                }
            }
        }
    }
    // function voteBySigs(uint id, bool[] memory _supports, bytes[] memory sigs) public {
    //     require(_supports.length == sigs.length);
    //     for (uint i = 0; i < _supports.length; i++) {
    //         bool support = _supports[i];
    //         bytes memory sig = sigs[i];
    //         uint gasStart = gasleft();
    //         bytes32 digest = voteDigest(id, support);
    //         address voter = ecrecoverFromSig(digest, sig);
    //         uint gasUsed = gasStart - gasleft();
    //         console.log("        > voteBySigs - gasUsed: ", gasUsed);
    //         require(voter != address(0), "Invalid signature");
    //         if (!voted[id][voter]) {
    //             _vote(voter, id, support);
    //         }
    //     }
    // }

    // TODO
    function execute(uint id) public {
        Proposal storage proposal = proposals[id];
        // require(proposal.start != 0 && block.timestamp >= proposal.start.add(votingDuration).add(executeDelay));

        // if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
        //     return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        // } else {
        //     return 0;
        // }

        // require(proposal.forVotes >= totalVotes.mul(quorum).div(1e18), "OptinoGov: Not enough votes to execute");
        proposal.executed = 1;

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success,) = proposal.targets[i].call{value: proposal.values[i]}(proposal.data[i]);
            require(success, "Execution failed");
        }

        emit Executed(msg.sender, id);
    }

    receive () external payable {
        // TODO depositDividend(address(0), msg.value);
    }
}
