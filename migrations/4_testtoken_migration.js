// import { BigNumber } from "bignumber.js";

var TestToken = artifacts.require("TestToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('deployer: ' + deployer);
  // deployer.deploy(TestToken, "ABC", "Abc", 18, tokenOwner, new web3.utils.BN("1000"), {from: deployer});
  deployer.deploy(TestToken, "ABC", "Abc", 18, owner, new web3.utils.BN("1000"), { from: owner, gas: 2000000 });

// string memory symbol, string memory name, uint8 decimals, address tokenOwner, uint initialSupply
};
