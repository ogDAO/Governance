const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

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
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account] = accountName;
    // addAddressNames(account, accountName);
    console.log("MyData.addAccount: " + account + " => " + accountName);
  }

  printBalances() {
    console.log("MyData.printBalances: Hello");
      
  }
}

const printBalancesOld = async function (commonVariables) {
  console.log("printBalancesOld: Hello: " + JSON.stringify(commonVariables));
}

/* Exporting the module */
module.exports = {
    MyData,
    ZERO_ADDRESS,
    TestToken,
    printBalancesOld,
}
