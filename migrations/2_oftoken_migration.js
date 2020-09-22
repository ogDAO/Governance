const BigNumber = require('bignumber.js');

var OFToken = artifacts.require("OFToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  deployer.deploy(OFToken, "OF", "Optino Fee", 18, owner, new BigNumber("1000000").shiftedBy(18), { from: owner, gas: 2000000 });
};
