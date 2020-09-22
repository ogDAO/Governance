var OFToken = artifacts.require("OFToken");
var OGToken = artifacts.require("OGToken");
var OptinoGov = artifacts.require("OptinoGov");

module.exports = function(deployer, network, accounts) {
  let owner = accounts[0];
  // console.log('owner: ' + owner);
  OGToken.deployed().then(ogToken => {
    OptinoGov.deployed().then(function (optinoGov) {
      ogToken.transferOwnership(optinoGov.address, {from:owner}).then(function() {
      	console.log('--- Setup completed ---')
      })
    })
  })

};
