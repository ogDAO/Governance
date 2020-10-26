pragma solidity ^0.7.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./CloneFactory.sol";
import "./OGTokenInterface.sol";
import "./Stake.sol";

// SPDX-License-Identifier: GPLv2
contract StakeFactory is CloneFactory {
    Stake public stakeTemplate;
    Stake[] public stakes;

    constructor() {
        stakeTemplate = new Stake();
    }

    function createClone() public {
        Stake newStake = Stake(createClone(address(stakeTemplate)));
        stakes.push(newStake);
    }
}
