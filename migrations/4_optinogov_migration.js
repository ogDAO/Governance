const BigNumber = require('bignumber.js');

var OGDToken = artifacts.require("OGDToken");
var OGToken = artifacts.require("OGToken");
var OptinoGov = artifacts.require("OptinoGov");
// var POAPOGTokenStation = artifacts.require("POAPOGTokenStation");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  deployer.deploy(OptinoGov, OGToken.address, { from: owner, gas: 5000000 });
};
