const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
const BigNumber = require('bignumber.js');
const util = require('util');

var OFToken = artifacts.require("OFToken");
var OGToken = artifacts.require("OGToken");
var OptinoGov = artifacts.require("OptinoGov");
var POAPOGTokenStation = artifacts.require("POAPOGTokenStation");
var TestToken = artifacts.require("TestToken");

class MyData {

  constructor(_accounts) {
    // this.accounts = _accounts;
    this.accounts = [];
    this.accountNames = {};
    this.owner = _accounts[0];
    this.user1 = _accounts[1];
    this.user2 = _accounts[2];
    this.user3 = _accounts[3];

    this.addAccount(_accounts[0], "Owner");
    this.addAccount(_accounts[1], "User1");
    this.addAccount(_accounts[2], "User2");
    this.addAccount(_accounts[3], "User3");

    this.baseBlock = null;

    this.tokenContracts = [];
    this.symbols = [];
    this.decimals = [];

    // OptinoGov testing
    this.ogToken = null;
    this.ofToken = null;
    this.feeToken = null;
    this.optinoGov = null;
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account.toLowerCase()] = accountName;
    // addAddressNames(account, accountName);
    // console.log("MyData.addAccount: " + account + " => " + accountName);
  }

  getShortAccountName(address) {
    if (address != null) {
      var a = address.toLowerCase();
      var n = this.accountNames[a];
      if (n !== undefined) {
        return n + ":" + address.substring(0, 6);
      }
    }
    return address;
  }

  async setBaseBlock() {
    this.baseBlock = await web3.eth.getBlockNumber();
    console.log("    - MyData.setBaseBlock - this.baseBlock: " + this.baseBlock);
  }

  async setOptinoGovData(ogToken, ofToken, feeToken, optinoGov) {
    this.ogToken = ogToken;
    this.ofToken = ofToken;
    this.feeToken = feeToken;
    this.optinoGov = optinoGov;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ofToken.address, "OFToken");
    this.addAccount(this.feeToken.address, "FeeToken");
    this.addAccount(this.optinoGov.address, "OptinoGov");
    // console.log("    - MyData.setOptinoGovData - ogToken: " + util.inspect(ogToken) + ", ofToken: " + util.inspect(ofToken) + ", optinoGov: " + util.inspect(optinoGov));
    console.log("    - MyData.setOptinoGovData - ogToken: " + ogToken + ", ofToken: " + ofToken + ", feeToken: " + feeToken + ", optinoGov: " + optinoGov);
    this.tokenContracts = [ogToken, ofToken, feeToken];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        let _symbol = tokenContract.symbol();
        let _decimals = tokenContract.decimals();
        let [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        console.log("    - MyData.setOptinoGovData - token: " + tokenContract.address + " => " + symbol + " " + decimals);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }


  async addToken(tokenContract) {
    let symbol = await tokenContract.symbol();
    let decimals = await tokenContract.decimals();
    console.log("    - MyData.addToken - tokenContract.address: " + tokenContract.address + " " + symbol + " " + decimals);
    this.tokenContracts.push(tokenContract);
    this.symbols.push(symbol);
    this.decimals.push(decimals);
  }

  padToken(s, decimals) {
    // var o = parseFloat(s).toFixed(18);
    // var o = web3.utils.fromWei(s, "ether", { pad: false });
    decimals = parseInt(decimals);
    var o = new BigNumber(s).shiftedBy(-decimals).toFixed(decimals);
    // var o = new BigNumber(s).shiftedBy(-18).toFixed(18);
    while (o.length < 27) {
      o = " " + o;
    }
    return o;
  }

  padLeft(s, n) {
    var o = s;
    while (o.length < n) {
      o = " " + o;
    }
    return o;
  }

  async printBalances() {
    var blockNumber = await web3.eth.getBlockNumber();
    var i = 0;
    var totalTokenBalances = [new BigNumber(0), new BigNumber(0), new BigNumber(0)];
    console.log("RESULT:  # Account                                             EtherBalanceChange               " + this.padLeft(this.symbols[0] || "???", 16) +  "               " + this.padLeft(this.symbols[1] || "???", 16) + " @ " + this.baseBlock.toString() + " -> " + blockNumber.toString());
    console.log("RESULT:                                                                                         " + this.padLeft(this.symbols[2] || "???", 16));
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    for (var i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = await web3.eth.getBalance(account, this.baseBlock);
      let etherBalance = await web3.eth.getBalance(account, blockNumber);
      let etherBalanceDiff = new BigNumber(etherBalance).minus(new BigNumber(etherBalanceBaseBlock));
      let tokenBalances = [new BigNumber(0), new BigNumber(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = new BigNumber(await this.tokenContracts[j].balanceOf(account));
        totalTokenBalances[j] = totalTokenBalances[j].plus(tokenBalances[j]);
      }
      console.log("RESULT: " + this.padLeft(i, 2) + " " + account + "  " + this.padToken(etherBalanceDiff, 18) + "    " + this.padToken(tokenBalances[0] || new BigNumber(0), this.decimals[0] || 18) + "    " + this.padToken(tokenBalances[1] || new BigNumber(0), this.decimals[1] || 18) + " " + this.accountNames[account]);
      console.log("RESULT:                                                                              " + this.padToken(tokenBalances[2] || new BigNumber(0), this.decimals[2] || 18));
    }
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT:                                                                              " + this.padToken(totalTokenBalances[0], this.decimals[0] || 18) + "    " + this.padToken(totalTokenBalances[1], this.decimals[1] || 18) + " Total Token Balances");
    console.log("RESULT:                                                                              " + this.padToken(totalTokenBalances[2], this.decimals[2] || 18));
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT: ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      console.log("RESULT: Token " + i + " @ " + tokenContract.address);
      let _symbol = tokenContract.symbol();
      let _name = tokenContract.name();
      let _decimals = tokenContract.decimals();
      let _totalSupply = tokenContract.totalSupply();
      let _owner = tokenContract.owner();
      let [symbol, name, decimals, totalSupply, owner] = await Promise.all([_symbol, _name, _decimals, _totalSupply, _owner]);
      console.log("RESULT: - symbol     : " + symbol);
      console.log("RESULT: - name       : " + name);
      console.log("RESULT: - decimals   : " + decimals);
      console.log("RESULT: - totalSupply: " + new BigNumber(totalSupply).shiftedBy(-decimals));
      console.log("RESULT: - owner      : " + this.getShortAccountName(owner));
    }
  }
}

// TODO: Delete
const printBalances = async function (commonVariables) {
  console.log("common.printBalances function: " + JSON.stringify(commonVariables));
}

/* Exporting the module */
module.exports = {
    MyData,
    ZERO_ADDRESS,
    OFToken,
    OGToken,
    OptinoGov,
    TestToken,
    printBalances,
}
