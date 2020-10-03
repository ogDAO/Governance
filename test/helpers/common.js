const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
const BigNumber = require('bignumber.js');
const util = require('util');

var OGToken = artifacts.require("OGToken");
var OGDToken = artifacts.require("OGDToken");
var OptinoGov = artifacts.require("OptinoGov");
// var POAPOGTokenStation = artifacts.require("POAPOGTokenStation");
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
    this.ogdToken = null;
    this.feeToken = null;
    this.optinoGov = null;
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account.toLowerCase()] = accountName;
    // addAddressNames(account, accountName);
    // console.log("MyData.addAccount: " + account + " => " + accountName);
  }

  // Using with geth devnet, have to unlock the accounts
  // async unlockAccounts(password) {
  //   for (var i = 0; i < this.accounts.length && i < 4; i++) {
  //     console.log("MyData.unlockAccounts: " + this.accounts[i] + " '" + password + "'");
  //     await web3.personal.unlockAccount(this.accounts[i], password, 100000);
  //     // if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
  //     //   personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
  //     // }
  //   }
  //   baseBlock = eth.blockNumber;
  // }


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
    // console.log("    - MyData.setBaseBlock - this.baseBlock: " + this.baseBlock);
  }

  async setOptinoGovData(ogToken, ogdToken, feeToken, optinoGov) {
    this.ogToken = ogToken;
    this.ogdToken = ogdToken;
    this.feeToken = feeToken;
    this.optinoGov = optinoGov;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.feeToken.address, "FeeToken");
    this.addAccount(this.optinoGov.address, "OptinoGov");
    // console.log("    - MyData.setOptinoGovData - ogToken: " + util.inspect(ogToken) + ", ogdToken: " + util.inspect(ogdToken) + ", optinoGov: " + util.inspect(optinoGov));
    // console.log("    - MyData.setOptinoGovData - ogToken: " + ogToken + ", ogdToken: " + ogdToken + ", feeToken: " + feeToken + ", optinoGov: " + optinoGov);
    this.tokenContracts = [ogToken, ogdToken, feeToken];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        let _symbol = tokenContract.symbol();
        let _decimals = tokenContract.decimals();
        let [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        // console.log("    - MyData.setOptinoGovData - token: " + tokenContract.address + " => " + symbol + " " + decimals);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async setOGDTokenData(ogdToken, feeToken) {
    this.ogdToken = ogdToken;
    this.feeToken = feeToken;
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.feeToken.address, "FeeToken");
    // console.log("    - MyData.setOptinoGovData - ogToken: " + util.inspect(ogToken) + ", ogdToken: " + util.inspect(ogdToken) + ", optinoGov: " + util.inspect(optinoGov));
    // console.log("    - MyData.setOptinoGovData - ogToken: " + ogToken + ", ogdToken: " + ogdToken + ", feeToken: " + feeToken + ", optinoGov: " + optinoGov);
    this.tokenContracts = [ogdToken, feeToken];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        let _symbol = tokenContract.symbol();
        let _decimals = tokenContract.decimals();
        let [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        // console.log("    - MyData.setOptinoGovData - token: " + tokenContract.address + " => " + symbol + " " + decimals);
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
    if (this.tokenContracts.length > 2) {
      console.log("RESULT:                                                                                         " + this.padLeft(this.symbols[2] || "???", 16));
    }
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    for (let i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = await web3.eth.getBalance(account, this.baseBlock);
      let etherBalance = await web3.eth.getBalance(account, blockNumber);
      let etherBalanceDiff = new BigNumber(etherBalance).minus(new BigNumber(etherBalanceBaseBlock));
      let tokenBalances = [new BigNumber(0), new BigNumber(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = new BigNumber(await this.tokenContracts[j].balanceOf(account));
        totalTokenBalances[j] = totalTokenBalances[j].plus(tokenBalances[j]);
      }
      console.log("RESULT: " + this.padLeft(i, 2) + " " + account + "  " + this.padToken(etherBalanceDiff, 18) + "    " + this.padToken(tokenBalances[0] || new BigNumber(0), this.decimals[0] || 18) + "    " + this.padToken(tokenBalances[1] || new BigNumber(0), this.decimals[1] || 18) + " " + this.getShortAccountName(account));
      if (this.tokenContracts.length > 2) {
        console.log("RESULT:                                                                              " + this.padToken(tokenBalances[2] || new BigNumber(0), this.decimals[2] || 18));
      }
    }
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT:                                                                              " + this.padToken(totalTokenBalances[0], this.decimals[0] || 18) + "    " + this.padToken(totalTokenBalances[1], this.decimals[1] || 18) + " Total Token Balances");
    if (this.tokenContracts.length > 2) {
      console.log("RESULT:                                                                              " + this.padToken(totalTokenBalances[2], this.decimals[2] || 18));
    }
    console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("RESULT: ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      console.log("RESULT: Token " + i + " " + this.getShortAccountName(tokenContract.address) + " @ " + tokenContract.address);
      let [symbol, name, decimals, totalSupply, owner] = await Promise.all([tokenContract.symbol(), tokenContract.name(), tokenContract.decimals(), tokenContract.totalSupply(), tokenContract.owner()]);
      console.log("RESULT: - symbol               : " + symbol);
      console.log("RESULT: - name                 : " + name);
      console.log("RESULT: - decimals             : " + decimals);
      console.log("RESULT: - totalSupply          : " + new BigNumber(totalSupply).shiftedBy(-decimals));
      console.log("RESULT: - owner                : " + this.getShortAccountName(owner));
      if (symbol == "OGD") {
        const dividendTokensLength = parseInt(await tokenContract.dividendTokensLength());
        console.log("RESULT: - dividendTokensLength : " + dividendTokensLength);
        for (let j = 0; j < dividendTokensLength; j++) {
          const dividendToken = await tokenContract.getDividendTokenByIndex(j);
          console.log("RESULT: - dividendToken        : " + j + " " + this.getShortAccountName(dividendToken[0]) + ", enabled: " + dividendToken[1]);
        }
        for (let j = 1; j < this.accounts.length && j < 4; j++) {
          let account = this.accounts[j];
          const dividendsOwing = await tokenContract.dividendsOwing(account);
          console.log("RESULT: - dividendsOwing        : " + j + " " + this.getShortAccountName(account));
          let tokenList = dividendsOwing[0];
          let owingList = dividendsOwing[1];
          for (let k = 0; k < dividendTokensLength; k++) {
            console.log("RESULT: -                       : " + this.getShortAccountName(tokenList[k]) + " " + owingList[k] + " " + new BigNumber(owingList[k]).shiftedBy(-18).toString());
          }
        }
      }
    }

    if (this.optinoGov != null) {
      console.log("RESULT: OptinoGov " + this.getShortAccountName(this.optinoGov.address) + " @ " + this.optinoGov.address);

      let [ogToken, ogdToken, maxLockTerm, rewardsPerSecond, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.maxLockTerm(), this.optinoGov.rewardsPerSecond(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
      let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, rewardPool, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.rewardPool(), this.optinoGov.totalVotes()]);
      let [proposalCount, stakeInfoLength] = await Promise.all([this.optinoGov.proposalCount(), this.optinoGov.stakeInfoLength()]);
      console.log("RESULT: - ogToken              : " + this.getShortAccountName(ogToken));
      console.log("RESULT: - ogdToken             : " + this.getShortAccountName(ogdToken));
      let decimals = 18;
      console.log("RESULT: - maxLockTerm          : " + maxLockTerm + " seconds = " + new BigNumber(maxLockTerm).dividedBy(60 * 60 * 24) + " days");
      console.log("RESULT: - rewardsPerSecond     : " + rewardsPerSecond + " = " + new BigNumber(rewardsPerSecond).multipliedBy(60 * 60 * 24).shiftedBy(-decimals) + " per day");
      console.log("RESULT: - proposalCost         : " + proposalCost + " = " + new BigNumber(proposalCost).shiftedBy(-decimals));
      console.log("RESULT: - proposalThreshold    : " + proposalThreshold + " = " + new BigNumber(proposalThreshold).shiftedBy(-16) + "%");
      console.log("RESULT: - quorum               : " + quorum + " = " + new BigNumber(quorum).shiftedBy(-16) + "%");
      console.log("RESULT: - quorumDecayPerSecond : " + quorumDecayPerSecond + " = " + new BigNumber(quorumDecayPerSecond).multipliedBy(60 * 60 * 24 * 365).shiftedBy(-16) + "% per year");
      console.log("RESULT: - votingDuration       : " + votingDuration + " seconds = " + new BigNumber(votingDuration).dividedBy(60 * 60 * 24) + " days");
      console.log("RESULT: - executeDelay         : " + executeDelay + " seconds = " + new BigNumber(executeDelay).dividedBy(60 * 60 * 24) + " days");
      console.log("RESULT: - rewardPool           : " + rewardPool + " = " + new BigNumber(rewardPool).shiftedBy(-decimals));
      console.log("RESULT: - totalVotes           : " + totalVotes + " = " + new BigNumber(totalVotes).shiftedBy(-decimals));
      console.log("RESULT: - proposalCount        : " + proposalCount);
      console.log("RESULT: - stakeInfoLength      : " + stakeInfoLength);
      // console.log("RESULT: gov.totalVotes=" + contract.totalVotes.call().shift(-18));
      // var proposalCount = contract.proposalCount.call();
      // console.log("RESULT: gov.proposalCount=" + proposalCount);
      // for (var proposalId = 1; proposalId <= proposalCount; proposalId++) {
      //   var proposal = contract.proposals.call(proposalId);
      //   console.log("RESULT: gov.proposals[" + proposalId + "] =" + JSON.stringify(proposal));
      // }
      //
      // var stakeInfoLength = contract.stakeInfoLength.call();
      // for (var stakeInfo_i = 0; stakeInfo_i < stakeInfoLength; stakeInfo_i++) {
      //   var stakeInfoKey = contract.stakeInfoIndex.call(stakeInfo_i);
      //   var stakeInfo = contract.getStakeInfoByKey.call(stakeInfoKey);
      //   console.log("RESULT: gov.getStakeInfoByKey[" + stakeInfoKey + "] =" + JSON.stringify(stakeInfo));
      // }
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
    OGToken,
    OGDToken,
    OptinoGov,
    TestToken,
    printBalances,
}
