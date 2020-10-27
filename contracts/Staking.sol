pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Owned.sol";

// SPDX-License-Identifier: GPLv2
contract Staking is Owned {
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
        uint tokens;
    }

    ERC20 public ogToken;
    StakingInfo public stakingInfo;
    mapping(address => Stake) public stakes;
    address[] public stakesIndex;

    event Staked(address indexed tokenOwner, uint tokens, uint duration, uint end);

    constructor() {
    }
    function initStaking(ERC20 _ogToken, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) public {
        initOwned(msg.sender);
        ogToken = _ogToken;
        stakingInfo = StakingInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }
    function getStakingInfo() public view returns (uint dataType, address[4] memory addresses, uint[6] memory uints, string memory string0, string memory string1, string memory string2, string memory string3) {
        (dataType, addresses, uints) = (stakingInfo.dataType, stakingInfo.addresses, stakingInfo.uints);
        string0 = stakingInfo.string0;
        string1 = stakingInfo.string1;
        string2 = stakingInfo.string2;
        string3 = stakingInfo.string3;
    }
    function getStakeByIndex(uint i) public view returns (address tokenOwner, Stake memory stake_) {
        require(i < stakesIndex.length, "Invalid stakings index");
        tokenOwner = stakesIndex[i];
        stake_ = stakes[tokenOwner];
    }
    function stakesLength() public view returns (uint) {
        return stakesIndex.length;
    }

    function _stake(address tokenOwner, uint tokens, uint duration) internal {
        require(duration > 0, "Invalid duration");
        Stake storage stake_ = stakes[tokenOwner];
        if (stake_.duration == 0) {
            stakes[tokenOwner] = Stake(uint64(duration), uint64(block.timestamp.add(duration)), uint64(stakesIndex.length), tokens);
            stake_ = stakes[tokenOwner];
            stakesIndex.push(tokenOwner);
            emit Staked(tokenOwner, tokens, duration, stake_.end);
        }
    }
    function stakeThroughFactory(address tokenOwner, uint tokens, uint duration) public onlyOwner {
        _stake(tokenOwner, tokens, duration);
    }
    function stake(uint tokens, uint duration) public {
        _stake(msg.sender, tokens, duration);
    }

    event Unstaked(address indexed tokenOwner, uint tokens);
    function unstake(uint tokens) public {
        Stake storage stake_ = stakes[msg.sender];
        require(uint(stake_.end) > block.timestamp, "Staking period still active");
        require(tokens >= stake_.tokens, "Unsufficient staked tokens");
        if (tokens > 0) {
            stake_.tokens = stake_.tokens.sub(tokens);
            stake_.duration = 0;
            stake_.end = uint64(block.timestamp - 1);
            emit Unstaked(msg.sender, tokens);
            require(ogToken.transfer(msg.sender, tokens), "OG transfer failed");
        }
    }
}
