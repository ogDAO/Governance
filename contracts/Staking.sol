pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./SafeMath.sol";
import "./OGTokenInterface.sol";
import "./Owned.sol";

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

    struct Stake {
        uint64 duration;
        uint64 end;
        uint64 index;
        uint balance;
    }

    uint public id;
    OGTokenInterface public ogToken;
    StakingInfo public stakingInfo;
    mapping(address => Stake) public stakes;
    address[] public stakesIndex;
    uint public weightedEndNumerator;
    uint public slashingFactor;
    uint public _totalSupply;
    mapping(address => mapping(address => uint)) allowed;

    event Staked(address indexed tokenOwner, uint tokens, uint duration, uint end);
    event Unstaked(address indexed tokenOwner, uint tokens, uint tokensWithSlashingFactor);
    event Slashed(uint slashingFactor, uint tokensBurnt);

    constructor() {
    }
    function initStaking(uint _id, OGTokenInterface _ogToken, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) public {
        initOwned(msg.sender);
        id = _id;
        ogToken = _ogToken;
        stakingInfo = StakingInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }

    bytes constant SYMBOLPREFIX = "OGS";
    uint8 constant DASH = 45;
    uint8 constant ZERO = 48;
    uint constant MAXSTAKINGINFOSTRINGLENGTH = 8;

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
        return _totalSupply.sub(stakes[address(0)].balance);
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return stakes[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) override external returns (bool success) {
        require(block.timestamp > stakes[msg.sender].end, "Stake period not ended");
        stakes[msg.sender].balance = stakes[msg.sender].balance.sub(tokens);
        stakes[to].balance = stakes[to].balance.add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) override external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
        require(block.timestamp > stakes[from].end, "Stake period not ended");
        stakes[from].balance = stakes[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        stakes[to].balance = stakes[to].balance.add(tokens);
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
    function getStakeByIndex(uint i) public view returns (address tokenOwner, Stake memory stake_) {
        require(i < stakesIndex.length, "Invalid index");
        tokenOwner = stakesIndex[i];
        stake_ = stakes[tokenOwner];
    }
    function stakesLength() public view returns (uint) {
        return stakesIndex.length;
    }
    function weightedEnd() public view returns (uint _weightedEnd) {
        if (_totalSupply > 0) {
            _weightedEnd = weightedEndNumerator.div(_totalSupply);
        }
        if (_weightedEnd < block.timestamp) {
            _weightedEnd = block.timestamp;
        }
    }

    function _stake(address tokenOwner, uint tokens, uint duration) internal {
        require(slashingFactor == 0, "Cannot stake if already slashed");
        require(duration > 0, "Invalid duration");
        Stake storage stake_ = stakes[tokenOwner];
        if (stake_.duration == 0) {
            stakes[tokenOwner] = Stake(uint64(duration), uint64(block.timestamp.add(duration)), uint64(stakesIndex.length), tokens);
            stake_ = stakes[tokenOwner];
            stakesIndex.push(tokenOwner);
            emit Staked(tokenOwner, tokens, duration, stake_.end);
        } else {
            require(block.timestamp + duration >= stake_.end, "Cannot shorten duration");
            weightedEndNumerator = weightedEndNumerator.sub(uint(stake_.end).mul(stake_.balance));
            _totalSupply = _totalSupply.sub(stake_.balance);
            stake_.duration = uint64(duration);
            stake_.end = uint64(block.timestamp.add(duration));
            stake_.balance = stake_.balance.add(tokens);
        }
        weightedEndNumerator = weightedEndNumerator.add(uint(stake_.end).mul(stake_.balance));
        _totalSupply = _totalSupply.add(stake_.balance);
        emit Transfer(address(0), tokenOwner, tokens);
    }
    function stakeThroughFactory(address tokenOwner, uint tokens, uint duration) public onlyOwner {
        _stake(tokenOwner, tokens, duration);
    }
    function stake(uint tokens, uint duration) public {
        require(ogToken.transferFrom(msg.sender, address(this), tokens), "OG transferFrom failed");
        _stake(msg.sender, tokens, duration);
    }

    function _unstake(address tokenOwner, uint tokens) internal {
        Stake storage stake_ = stakes[tokenOwner];
        require(uint(stake_.end) < block.timestamp, "Staking period still active");
        require(tokens <= stake_.balance, "Unsufficient staked balance");
        if (tokens > 0) {
            weightedEndNumerator = weightedEndNumerator.sub(uint(stake_.end).mul(stake_.balance));
            _totalSupply = _totalSupply.sub(stake_.balance);
            stake_.balance = stake_.balance.sub(tokens);
            if (stake_.balance == 0) {
                uint removedIndex = uint(stake_.index);
                uint lastIndex = stakesIndex.length - 1;
                address lastStakeAddress = stakesIndex[lastIndex];
                stakesIndex[removedIndex] = lastStakeAddress;
                stakes[lastStakeAddress].index = uint64(removedIndex);
                delete stakesIndex[lastIndex];
                if (stakesIndex.length > 0) {
                    stakesIndex.pop();
                }
            } else {
                weightedEndNumerator = weightedEndNumerator.add(uint(stake_.end).mul(stake_.balance));
                _totalSupply = _totalSupply.add(stake_.balance);
            }
            uint tokensWithSlashingFactor = tokens.sub(tokens.mul(slashingFactor).div(10**18));
            require(ogToken.transfer(tokenOwner, tokensWithSlashingFactor), "OG transfer failed");
            emit Unstaked(msg.sender, tokens, tokensWithSlashingFactor);
        }
    }
    function unstake(uint tokens) public {
        _unstake(msg.sender, tokens);
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
