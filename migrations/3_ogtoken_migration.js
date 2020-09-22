const BigNumber = require('bignumber.js');

var OGToken = artifacts.require("OGToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  deployer.deploy(OGToken, "OG", "Optino Governance", 18, owner, new BigNumber("1000000").shiftedBy(18), { from: owner, gas: 2000000 });
};
