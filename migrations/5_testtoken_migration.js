const BigNumber = require('bignumber.js');

var TestToken = artifacts.require("TestToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  deployer.deploy(TestToken, "TEST", "Test", 18, owner, new BigNumber("1000000").shiftedBy(18), { from: owner, gas: 2000000 });
};
