const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
const BigNumber = require('bignumber.js');

var TestToken = artifacts.require("TestToken");

/* Creating a class with all common Variables */
class MyData {
  // var accounts = [];
  // var accountNames = {};

  constructor(_accounts) {
    // var accounts = [];
    // var accountNames = {};
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
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account] = accountName;
    // addAddressNames(account, accountName);
    // console.log("MyData.addAccount: " + account + " => " + accountName);
  }

  async setBaseBlock() {
    this.baseBlock = await web3.eth.getBlockNumber();
    console.log("    - MyData.setBaseBlock - this.baseBlock: " + this.baseBlock);
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
    var totalTokenBalances = [new BigNumber(0), new BigNumber(0)];
    console.log("RESULT:  # Account                                             EtherBalanceChange               " + this.padLeft(this.symbols[0] || "???", 16) +  "               " + this.padLeft(this.symbols[1] || "???", 16));
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    for (var i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = await web3.eth.getBalance(account, this.baseBlock);
      let etherBalance = await web3.eth.getBalance(account, blockNumber);
      // let etherBalanceDiff = new web3.utils.BN(etherBalance).sub(new web3.utils.BN(etherBalanceBaseBlock));
      let etherBalanceDiff = new BigNumber(etherBalance).minus(new BigNumber(etherBalanceBaseBlock));
      let tokenBalances = [new BigNumber(0), new BigNumber(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = new BigNumber(await this.tokenContracts[j].balanceOf(account));
        totalTokenBalances[j] = totalTokenBalances[j].plus(tokenBalances[j]);
      }
      console.log("RESULT: " + this.padLeft(i, 2) + " " + account + "  " + this.padToken(etherBalanceDiff, 18) + "    " + this.padToken(tokenBalances[0], this.decimals[0]) + "    " + this.padToken(tokenBalances[1] || new BigNumber(0), this.decimals[1] || 18) + " " + this.accountNames[account]);
    }
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT:                                                                              " + this.padToken(totalTokenBalances[0], this.decimals[0]) + "    " + this.padToken(totalTokenBalances[1], this.decimals[1] || 18) + " Total Token Balances");
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT: ");
  }
}

const printBalances = async function (commonVariables) {
  console.log("common.printBalances function: " + JSON.stringify(commonVariables));
}

/* Exporting the module */
module.exports = {
    MyData,
    ZERO_ADDRESS,
    TestToken,
    printBalances,
}
