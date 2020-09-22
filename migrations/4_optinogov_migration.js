const BigNumber = require('bignumber.js');

var OFToken = artifacts.require("OFToken");
var OGToken = artifacts.require("OGToken");
var OptinoGov = artifacts.require("OptinoGov");
var POAPOGTokenStation = artifacts.require("POAPOGTokenStation");
var TestToken = artifacts.require("TestToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('deployer: ' + deployer);
  // deployer.deploy(TestToken, "ABC", "Abc", 18, tokenOwner, new web3.utils.BN("1000"), {from: deployer});
  deployer.deploy(OptinoGov, OGToken.address, { from: owner, gas: 5000000 });

};
