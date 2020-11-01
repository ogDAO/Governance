pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./ERC20.sol";
import "./CloneFactory.sol";
import "./OGTokenInterface.sol";
import "./Owned.sol";
import "./Staking.sol";

// SPDX-License-Identifier: GPLv2
contract StakingFactory is CloneFactory, Owned {
    Staking public stakingTemplate;
    OGTokenInterface public ogToken;

    mapping(bytes32 => Staking) public stakings;
    bytes32[] public stakingsIndex;
    mapping(Staking => bool) public contracts;

    event StakingCreated(bytes32 indexed key, Staking indexed staking);

    constructor(OGTokenInterface _ogToken) {
        initOwned(msg.sender);
        ogToken = _ogToken;
        stakingTemplate = new Staking();
    }

    function getStakingByIndex(uint i) public view returns (bytes32 key, Staking staking) {
        require(i < stakingsIndex.length, "Invalid stakings index");
        key = stakingsIndex[i];
        staking = stakings[key];
    }
    function stakingsLength() public view returns (uint) {
        return stakingsIndex.length;
    }

    function addStakingForToken(uint tokens, uint duration, address tokenAddress, string memory name) external returns (Staking staking) {
        return _staking(tokens, duration, 1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], [name, "", "", ""]);
    }

    function _staking(uint tokens, uint duration, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) internal returns (Staking staking) {
        bytes32 key = keccak256(abi.encodePacked(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]));
        staking = stakings[key];
        if (address(staking) == address(0)) {
            staking = Staking(createClone(address(stakingTemplate)));
            staking.initStaking(stakingsIndex.length, ogToken, dataType, addresses, uints, strings);
            stakings[key] = staking;
            stakingsIndex.push(key);
            contracts[staking] = true;
            emit StakingCreated(key, staking);
        }
        require(ogToken.transferFrom(msg.sender, address(staking), tokens), "OG transferFrom failed");
        staking.stakeThroughFactory(msg.sender, tokens, duration);
    }

    function slash(Staking staking, uint slashingFactor) public onlyOwner {
        staking.slash(slashingFactor);
    }

    function mintOGTokens(address tokenOwner, uint tokens) public {
        require(contracts[Staking(msg.sender)], "Caller not child");
        console.log("        >   %s -> StakingFactory.mintOGTokens(%s, %s)", msg.sender, tokenOwner, tokens);
        require(ogToken.mint(tokenOwner, tokens), "OG mint failed");
    }

    // function addStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    //     bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    //     StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    //     if (stakeInfo.dataType == 0) {
    //         stakeInfoData[stakingKey] = StakeInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    //         stakeInfoIndex.push(stakingKey);
    //         emit StakeInfoAdded(stakingKey, dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    //     }
    //     _addStake(tokens, stakingKey);
    // }
    // function subStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    //     bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    //     _subStake(tokens, stakingKey);
    // }
    // function _addStake(uint tokens, bytes32 stakingKey) internal {
    //     Commitment storage committment = commitments[msg.sender];
    //     require(committment.tokens > 0, "OptinoGov: Commit before staking");
    //     require(committment.tokens >= committment.staked + tokens, "OptinoGov: Insufficient tokens to stake");
    //     committment.staked = committment.staked.add(tokens);
    //     // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].add(tokens);
    //     // TODO emit Staked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
    // }
    // function _subStake(uint tokens, bytes32 stakingKey) internal {
    //     Commitment storage committment = commitments[msg.sender];
    //     require(committment.tokens > 0, "OptinoGov: Commit and stake tokens before unstaking");
    //     // TODO require(committment.stakes[stakingKey] >= tokens, "OptinoGov: Insufficient staked tokens");
    //     committment.staked = committment.staked.sub(tokens);
    //     // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].sub(tokens);
    //     // TODO emit Unstaked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
    // }

}
