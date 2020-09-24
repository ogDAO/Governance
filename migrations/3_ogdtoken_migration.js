const BigNumber = require('bignumber.js');

var OGDToken = artifacts.require("OGDToken");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  deployer.deploy(OGDToken, "OGD", "Optino Governance Dividend", 18, owner, new BigNumber("1000000").shiftedBy(18), { from: owner, gas: 2000000 });
};
