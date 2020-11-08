const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const SECONDS_PER_DAY = 24 * 60 * 60;
const SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
const { BigNumber } = require("ethers");
const util = require('util');
const { expect, assert } = require("chai");

class Data {

  constructor() {
    this.accounts = [];
    this.accountNames = {};
    this.contractsByAddress = {};
    this.baseBlock = null;

    this.tokenContracts = [];
    this.symbols = [];
    this.decimals = [];

    // OptinoGov testing
    this.ogToken = null;
    this.ogdToken = null;
    this.ogRewardCurve = null;
    this.voteWeightCurve = null;
    this.optinoGov = null;
    this.fee0Token = null;
    this.fee1Token = null;
    this.fee2Token = null;
    this.stakingRewardCurve = null;
    this.stakingFactory = null;

    // this.ethUsd = BigNumber.from("385.67");
    this.ethUsd = ethers.utils.parseUnits("385.67", 18);
  }

  async init() {
    [this.ownerSigner, this.user1Signer, this.user2Signer, this.user3Signer, this.user4Signer] = await ethers.getSigners();
    [this.owner, this.user1, this.user2, this.user3, this.user4] = await Promise.all([this.ownerSigner.getAddress(), this.user1Signer.getAddress(), this.user2Signer.getAddress(), this.user3Signer.getAddress(), this.user4Signer.getAddress()]);
    this.addAccount(this.owner, "Owner");
    this.addAccount(this.user1, "User1");
    this.addAccount(this.user2, "User2");
    this.addAccount(this.user3, "User3");
    this.addAccount(this.user4, "User4");
    this.baseBlock = await ethers.provider.getBlockNumber();
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account.toLowerCase()] = accountName;
    console.log("        Address " + account + " => " + this.getShortAccountName(account));
  }

  addContract(contract, contractName) {
    this.contractsByAddress[contract.address.toLowerCase()] = {
      address: contract.address,
      name: contractName,
      interface: contract.interface,
    };
  }

  getShortAccountName(address) {
    if (address == ZERO_ADDRESS) {
      return "ETH|null:" + ZERO_ADDRESS.substring(0, 6);
    }
    if (address != null) {
      var a = address.toLowerCase();
      var n = this.accountNames[a];
      if (n !== undefined) {
        return n + ":" + address.substring(0, 6);
      }
    }
    return address;
  }

  // async setSimpleCurveData(ogRewardCurve) {
  //   this.ogRewardCurve = ogRewardCurve;
  //   this.addAccount(this.ogRewardCurve.address, "SimpleCurve");
  //   this.addContract(this.ogRewardCurve, "SimpleCurve");
  // }

  async setOptinoGovData(ogToken, ogdToken, ogRewardCurve, voteWeightCurve, optinoGov, fee0Token) {
    this.ogToken = ogToken;
    this.ogdToken = ogdToken;
    this.ogRewardCurve = ogRewardCurve;
    this.voteWeightCurve = voteWeightCurve;
    this.optinoGov = optinoGov;
    this.fee0Token = fee0Token;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.ogRewardCurve.address, "OGRewardCurve");
    this.addAccount(this.voteWeightCurve.address, "VoteWeightCurve");
    this.addAccount(this.optinoGov.address, "OptinoGov");
    this.addAccount(this.fee0Token.address, "Fee0Token");

    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.ogRewardCurve, "OGRewardCurve");
    this.addContract(this.voteWeightCurve, "VoteWeightCurve");
    this.addContract(this.optinoGov, "OptinoGov");
    this.addContract(this.fee0Token, "Fee0Token");

    this.tokenContracts = [optinoGov, ogToken, ogdToken, fee0Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token) {
    this.ogdToken = ogdToken;
    this.fee0Token = fee0Token;
    this.fee1Token = fee1Token;
    this.fee2Token = fee2Token;
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.fee1Token.address, "Fee1Token");
    this.addAccount(this.fee2Token.address, "Fee2Token");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.fee0Token, "Fee0Token");
    this.addContract(this.fee1Token, "Fee1Token");
    this.addContract(this.fee2Token, "Fee2Token");
    this.tokenContracts = [ogdToken, fee0Token, fee1Token, fee2Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async setStakingFactoryData(ogToken, stakingRewardCurve, fee0Token, stakingFactory) {
    this.ogToken = ogToken;
    this.stakingRewardCurve = stakingRewardCurve;
    this.fee0Token = fee0Token;
    this.stakingFactory = stakingFactory;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.stakingRewardCurve.address, "StakingRewardCurve");
    this.addAccount(this.stakingFactory.address, "StakingFactory");
    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.fee0Token, "Fee0Token");
    this.addContract(this.stakingRewardCurve, "StakingRewardCurve");
    this.addContract(this.stakingFactory, "StakingFactory");
    this.tokenContracts = [ogToken, fee0Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async addStakingData(staking) {
    this.addAccount(staking.address, "Staking");
    this.addContract(staking, "Staking");
    const _symbol = staking.symbol();
    const _decimals = staking.decimals();
    const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
    this.tokenContracts.push(staking);
    this.symbols.push(symbol);
    this.decimals.push(decimals);
  }

  padToken(s, decimals) {
    decimals = parseInt(decimals);
    var o = ethers.utils.formatUnits(s, decimals);
    while (o.length < 25) {
      o = " " + o;
    }
    return o;
  }

  padLeft(s, n) {
    var o = s.toString();
    while (o.length < n) {
      o = " " + o;
    }
    return o;
  }

  padRight(s, n) {
    var o = s;
    while (o.length < n) {
      o = o + " ";
    }
    return o;
  }

  printEvent(log) {
    var address = log.address;
    var _contract = this.contractsByAddress[address.toLowerCase()];
    if (_contract != null) {
      var data = _contract.interface.parseLog(log);
      var result = _contract.name + "." + data.name + "(";
      let separator = "";
      data.eventFragment.inputs.forEach((a) => {
        result = result + separator + a.name + ": ";
        if (a.type == 'address') {
          result = result + this.getShortAccountName(data.args[a.name].toString());
        } else if (a.type == 'uint256') {
          if (a.name == 'tokens' || a.name == 'amount' || a.name == 'balance' || a.name == 'votes' || a.name == 'reward' || a.name == 'rewardPool' || a.name == 'totalVotes' || a.name == 'tokensBurnt' || a.name == 'tokensWithSlashingFactor' || a.name == 'rewardWithSlashingFactor') {
            // TODO Get decimals from token contracts, and only convert for token contract values
            result = result + ethers.utils.formatUnits(data.args[a.name], 18);
          } else if (a.name == 'slashingFactor') {
            result = result + ethers.utils.formatUnits(data.args[a.name], 16) + "%";
          } else {
            result = result + data.args[a.name].toString();
          }
        } else {
          result = result + data.args[a.name].toString();
        }
        separator = ", ";
      });
      result = result + ")";
      console.log("        + " + result);
    } else {
      console.log("        + " + JSON.stringify(log));
    }
  }

  //-----------------------------------------------------------------------------
  // Pause for {x} seconds
  //-----------------------------------------------------------------------------
  pause(message, addSeconds) {
    var time = new Date((parseInt(new Date().getTime()/1000) + addSeconds) * 1000);
    console.log("        Pausing '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
    while ((new Date()).getTime() <= time.getTime()) {
    }
    console.log("        Paused '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
    console.log("        ");
  }

  async expectException(message, searchString, promise) {
    try {
      await promise;
    } catch (e) {
      assert(e.toString().indexOf(searchString) >= 0, message + " - '" + searchString + "' not found in error message '" + e.toString() + "'");
      console.log("        " + message + " - Exception '" + searchString + "' thrown as expected");
      return;
    }
    assert.fail(message + " - Exception '" + searchString + "' was not thrown as expected");
  }

  async printTxData(message, tx) {
    const receipt = await tx.wait();
    var fee = receipt.gasUsed.mul(tx.gasPrice);
    var feeUsd = fee.mul(this.ethUsd).div(ethers.utils.parseUnits("1", 18));
    console.log("        " + message + " - gasUsed: " + receipt.gasUsed.toString() + ", fee: " + ethers.utils.formatUnits(fee, 18) + ", feeUsd: " + ethers.utils.formatUnits(feeUsd, 18) + ", @ " + ethers.utils.formatUnits(tx.gasPrice, 9) + " gwei & " + ethers.utils.formatUnits(this.ethUsd,18) + " ETH/USD, " + tx.hash);
    receipt.logs.forEach((log) => {
      this.printEvent(log);
    });
  }

  termString(term) {
    var s = "";
    if (term < 0) {
      term = -term;
      s = "-";
    }
    var secs = parseInt(term);
    var mins = parseInt(secs / 60);
    secs = secs % 60;
    var hours = parseInt(mins / 60);
    mins = mins % 60;
    var days = parseInt(hours / 24);
    hours = hours % 24;
    var years = parseInt(days / 365);
    days = days % 365;
    if (years > 0) {
      s += years + "y";
    }
    if (days > 0) {
      s += days + "d";
    }
    if (hours > 0) {
      s += hours + "h";
    }
    if (mins > 0) {
      s += mins + "m";
    }
    if (secs > 0) {
      s += secs + "s";
    }
    return s;
  }

  async printBalances() {
    console.log("        ");
    const blockNumber = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock("latest");
    const now = block.timestamp;
    // console.log("        block: " + util.inspect(block));
    // console.log("        now: " + now);
    const totalTokenBalances = [];
    let line = "         # Account                                        ΔETH";
    let separator = "        -- --------------------------- -----------------------";
    for (let t = 0; t < this.tokenContracts.length; t++) {
      line = line + "         " + this.padLeft(this.symbols[t] || "???", 16);
      separator = separator + " ------------------------";
      totalTokenBalances.push(BigNumber.from(0));
    }
    console.log(line);
    console.log(separator);
    for (let i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = (await ethers.provider.getBalance(account, this.baseBlock)).toString();
      let etherBalance = await ethers.provider.getBalance(account, blockNumber);
      let etherBalanceDiff = etherBalance.sub(etherBalanceBaseBlock);
      let tokenBalances = [BigNumber.from(0), BigNumber.from(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = await this.tokenContracts[j].balanceOf(account);
        totalTokenBalances[j] = totalTokenBalances[j].add(tokenBalances[j]);
      }
      line = "        " + this.padLeft(i, 2) + " " + this.padRight(this.getShortAccountName(account), 25) + " " + this.padToken(etherBalanceDiff, 18);
      for (let t = 0; t < this.tokenContracts.length; t++) {
        line = line + this.padToken(tokenBalances[t] || BigNumber.from(0), this.decimals[t] || 18);
      }
      console.log(line);
    }
    console.log(separator);
    line = "           Totals                                          ";
    for (let t = 0; t < this.tokenContracts.length; t++) {
      line = line + this.padToken(totalTokenBalances[t] || BigNumber.from(0), this.decimals[t] || 18);
    }
    console.log(line);
    console.log(separator);
    console.log("        ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      let [symbol, name, decimals, totalSupply] = await Promise.all([tokenContract.symbol(), tokenContract.name(), tokenContract.decimals(), tokenContract.totalSupply()]);
      let owner;
      try {
        owner = await tokenContract.owner();
      } catch (e) {
        owner = "n/a";
      }
      console.log("        Token " + i + " symbol: '" + symbol + "', name: '" + name + "', decimals: " + decimals + ", totalSupply: " + ethers.utils.formatUnits(totalSupply, decimals) + ", owner: " + this.getShortAccountName(owner) + ", address: " + this.getShortAccountName(tokenContract.address));
      if (symbol == "OptinoGov" && this.optinoGov != null) {
        // console.log("        OptinoGov " + this.getShortAccountName(this.optinoGov.address) + " @ " + this.optinoGov.address);
        let [ogToken, ogdToken, ogRewardCurve, voteWeightCurve, accountsLength, maxDuration, rewardsPerSecond, rewardsPerYear, collectRewardForFee, collectRewardForDelay, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.ogRewardCurve(), this.optinoGov.voteWeightCurve(), this.optinoGov.accountsLength(), this.optinoGov.maxDuration(), this.optinoGov.rewardsPerSecond(), this.optinoGov.rewardsPerYear(), this.optinoGov.collectRewardForFee(), this.optinoGov.collectRewardForDelay(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
        let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, rewardPool, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.rewardPool(), this.optinoGov.totalVotes()]);
        let [proposalCount /*, stakeInfoLength*/] = await Promise.all([this.optinoGov.proposalCount()/*, this.optinoGov.stakeInfoLength()*/]);
        console.log("        - ogToken              : " + this.getShortAccountName(ogToken));
        console.log("        - ogdToken             : " + this.getShortAccountName(ogdToken));
        console.log("        - ogRewardCurve        : " + this.getShortAccountName(ogRewardCurve));
        console.log("        - voteWeightCurve      : " + this.getShortAccountName(voteWeightCurve));
        let decimals = 18;
        console.log("        - maxDuration          : " + maxDuration + " seconds = " + maxDuration.div(60 * 60 * 24) + " days");
        console.log("        - rewardsPerSecond     : " + rewardsPerSecond + " = " + ethers.utils.formatUnits(rewardsPerSecond, 18) + " = " + ethers.utils.formatUnits(rewardsPerSecond.mul(60 * 60 * 24), decimals) + " per day");
        console.log("        - collectRewardForFee  : " + collectRewardForFee + " = " + ethers.utils.formatUnits(collectRewardForFee, 16) + "%");
        console.log("        - collectRewardForDelay: " + collectRewardForDelay + " seconds = " + collectRewardForDelay.div(60 * 60 * 24) + " days");
        console.log("        - proposalCost         : " + proposalCost + " = " + ethers.utils.formatUnits(proposalCost, decimals));
        console.log("        - proposalThreshold    : " + proposalThreshold + " = " + ethers.utils.formatUnits(proposalThreshold, 16) + "%");
        console.log("        - quorum               : " + quorum + " = " + ethers.utils.formatUnits(quorum, 16) + "%");
        console.log("        - quorumDecayPerSecond : " + quorumDecayPerSecond + " = " + ethers.utils.formatUnits(quorumDecayPerSecond.mul(60 * 60 * 24 * 365), 16) + "% per year");
        console.log("        - votingDuration       : " + votingDuration + " seconds = " + votingDuration.div(60 * 60 * 24) + " days");
        console.log("        - executeDelay         : " + executeDelay + " seconds = " + executeDelay.div(60 * 60 * 24) + " days");
        console.log("        - rewardPool           : " + rewardPool + " = " + ethers.utils.formatUnits(rewardPool, decimals));
        console.log("        - totalVotes           : " + totalVotes + " = " + ethers.utils.formatUnits(totalVotes, decimals));
        console.log("        - rewardsPerYear       : " + ethers.utils.formatUnits(rewardsPerYear, 16) + "% compounding daily/simple partial end, rewardsPerSecond: " + ethers.utils.formatUnits(rewardsPerYear.div(60*60*24*365), 16) + "%");
        console.log("        - proposalCount        : " + proposalCount);
        // console.log("        - stakeInfoLength      : " + stakeInfoLength);
        // console.log("        - accountsLength       : " + accountsLength);
        console.log("          # Account                Duration              End                    Rate%                  Balance                    Votes Delegatee                     Delegated Votes                  Accrued    Term");
        console.log("         -- -------------------- ---------- ---------------- ------------------------ ------------------------ ------------------------ -------------------- ------------------------ ------------------------ -------");
        for (let j = 0; j < accountsLength; j++) {
          const _a = await this.optinoGov.getAccountByIndex(j);
          const accruedReward = await tokenContract.accruedReward(_a.tokenOwner);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padRight(this.getShortAccountName(_a.tokenOwner), 20) + " " +
            this.padLeft(this.termString(_a.account.duration.toString()), 10) + " " +
            this.padLeft(this.termString(parseInt(_a.account.end.toString())-now), 16) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.balance, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.votes, 18), 24) + " " +
            this.padRight(this.getShortAccountName(_a.account.delegatee), 20) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.delegatedVotes, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(accruedReward[0], 18), 24) + " " +
            this.padLeft(accruedReward[1].toString(), 7));
        }
        console.log("         -- -------------------- ---------- ---------------- ------------------------ ------------------------ ------------------------ -------------------- ------------------------ ------------------------ -------");
      } else if (symbol == "OGD") {
        const dividendTokensLength = parseInt(await tokenContract.dividendTokensLength());
        // console.log("        - dividendTokensLength : " + dividendTokensLength);
        console.log("          # Dividend         Enabled                  Unclaimed");
        console.log("         -- ---------------- ------- --------------------------");
        let dividendHeader = "";
        let dividendSeparator = "         -- ------------------";
        for (let j = 0; j < dividendTokensLength; j++) {
          const dividendToken = await tokenContract.getDividendTokenByIndex(j);
          const unclaimedDividends = await tokenContract.unclaimedDividends(dividendToken[0]);
          dividendHeader = dividendHeader + this.padLeft("Owing " + this.getShortAccountName(dividendToken[0]), 24) + " " + this.padLeft("New " + this.getShortAccountName(dividendToken[0]), 24) + " ";
          dividendSeparator = dividendSeparator + " ------------------------ ------------------------";
          console.log("         " + this.padLeft(j, 2) + " " + this.padRight(this.getShortAccountName(dividendToken[0]), 18) + "  " + this.padRight(dividendToken[1].toString(), 6) + " " + this.padLeft(ethers.utils.formatUnits(unclaimedDividends, 18), 24));
        }
        console.log("         -- ---------------- ------- --------------------------");
        if (dividendTokensLength > 0) {
          console.log("          # Account            " + dividendHeader);
          console.log(dividendSeparator);
          for (let j = 1; j < this.accounts.length; j++) {
            let account = this.accounts[j];
            let accountName = this.getShortAccountName(account);
            if (!accountName.startsWith("Fee") && !accountName.startsWith("OG") && !accountName.startsWith("Vote")) {
              const dividendsOwing = await tokenContract.dividendsOwing(account);
              let result = "";
              let tokenList = dividendsOwing[0];
              let owingList = dividendsOwing[1];
              let newOwingList = dividendsOwing[2];
              for (let k = 0; k < dividendTokensLength; k++) {
                result = result + this.padLeft(ethers.utils.formatUnits(owingList[k], 18), 24) + " " + this.padLeft(ethers.utils.formatUnits(newOwingList[k], 18), 24) + " ";
              }
              console.log("         " + this.padLeft(j, 2) + " " + this.padRight(this.getShortAccountName(account), 18) + " " + result);
            }
          }
          console.log(dividendSeparator);
        }
      } else if (symbol.startsWith("OGS")) {
        const [stakingInfo, owner, accountsLength, rewardsPerYear, weightedEnd, weightedEndNumerator, /*weightedDurationDenominator,*/ slashingFactor] = await Promise.all([tokenContract.getStakingInfo(), tokenContract.owner(), tokenContract.accountsLength(), tokenContract.rewardsPerYear(), tokenContract.weightedEnd(), tokenContract.weightedEndNumerator(), /*tokenContract.weightedDurationDenominator(),*/ tokenContract.slashingFactor()]);
        console.log("        - staking @ " + this.getShortAccountName(tokenContract.address) + ", owner: " + this.getShortAccountName(owner));
        console.log("          - dataType                   : " + stakingInfo.dataType  .toString());
        console.log("          - addresses                  : " + JSON.stringify(stakingInfo.addresses.map((x) => { return this.getShortAccountName(x); })));
        console.log("          - uints                      : " + JSON.stringify(stakingInfo.uints.map((x) => { return x.toString(); })));
        console.log("          - strings                    : " + JSON.stringify([stakingInfo.string0, stakingInfo.string1, stakingInfo.string2, stakingInfo.string3]));
        console.log("          - rewardsPerYear             : " + ethers.utils.formatUnits(rewardsPerYear, 16) + "% compounding daily/simple partial end, rewardsPerSecond: " + ethers.utils.formatUnits(rewardsPerYear.div(60*60*24*365), 16) + "%");
        // console.log("          - weightedDurationDenominator: " + new BigNumber(weightedDurationDenominator.toString()).shiftedBy(-18));
        console.log("          - weightedEnd                : " + weightedEnd + " = " + ethers.utils.formatUnits(weightedEndNumerator, decimals) + "/" + ethers.utils.formatUnits(totalSupply, decimals));
        console.log("          - slashingFactor             : " + ethers.utils.formatUnits(slashingFactor, 16) + "%");
        // console.log("          - accountsLength             : " + accountsLength);
        console.log("          # Account              Duration        End      Index                  Balance           Accrued Reward    Term");
        console.log("         -- -------------------- -------- ---------- ---------- ------------------------ ------------------------ -------");
        for (let k = 0; k < accountsLength; k++) {
          const account = await tokenContract.getAccountByIndex(k);
          const accruedReward = await tokenContract.accruedReward(account.tokenOwner);
          console.log("         " + this.padLeft(k, 2) + " " +
            this.padRight(this.getShortAccountName(account.tokenOwner), 20) + " " +
            this.padLeft(account.account.duration.toString(), 8) + " " +
            this.padLeft(account.account.end.toString(), 10) + " " +
            this.padLeft(account.account.index.toString(), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(account.account.balance, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(accruedReward[0], 18), 24) + " " +
            this.padLeft(accruedReward[1].toString(), 7));
        }
        console.log("         -- -------------------- -------- ---------- ---------- ------------------------ ------------------------ -------");
      }
    }

    if (this.ogRewardCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.ogRewardCurve.owner(), this.ogRewardCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.ogRewardCurve.address) + " @ " + this.ogRewardCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term                Rate APY%                  Rate/s%");
        console.log("         -- ---------- ------------------------ ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.ogRewardCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate.div(365 * 24 * 60 * 60), 16), 24));
        }
        console.log("         -- ---------- ------------------------ ------------------------");
    }
    if (this.voteWeightCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.voteWeightCurve.owner(), this.voteWeightCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.voteWeightCurve.address) + " @ " + this.voteWeightCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term             Vote Weight%");
        console.log("         -- ---------- ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.voteWeightCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24));
        }
        console.log("         -- ---------- ------------------------");
    }
    if (this.stakingRewardCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.stakingRewardCurve.owner(), this.stakingRewardCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.stakingRewardCurve.address) + " @ " + this.stakingRewardCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term                Rate APY%                  Rate/s%");
        console.log("         -- ---------- ------------------------ ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.stakingRewardCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate.div(365 * 24 * 60 * 60), 16), 24));
        }
        console.log("         -- ---------- ------------------------ ------------------------");
    }

    if (this.stakingFactory != null) {
      console.log("        StakingFactory " + this.getShortAccountName(this.stakingFactory.address) + " @ " + this.stakingFactory.address);
      const [stakingTemplate, ogToken, stakingRewardCurve, stakingsLength] = await Promise.all([this.stakingFactory.stakingTemplate(), this.stakingFactory.ogToken(), this.stakingFactory.stakingRewardCurve(), this.stakingFactory.stakingsLength()]);
      console.log("        - stakingTemplate        : " + this.getShortAccountName(stakingTemplate));
      console.log("        - ogToken                : " + this.getShortAccountName(ogToken));
      console.log("        - stakingRewardCurve     : " + this.getShortAccountName(stakingRewardCurve));
      console.log("        - stakingsLength         : " + stakingsLength);
      const Staking = await ethers.getContractFactory("Staking");
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await this.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        const [stakingInfo, owner, accountsLength, totalSupply, weightedEnd, slashingFactor] = await Promise.all([staking.getStakingInfo(), staking.owner(), staking.accountsLength(), staking.totalSupply(), staking.weightedEnd(), staking.slashingFactor()]);
        console.log("          - staking " + j + " @ " + this.getShortAccountName(stakingAddress[1]) + ", owner: " + this.getShortAccountName(owner));
        // console.log("          - dataType      : " + stakingInfo.dataType  .toString());
        // console.log("          - addresses     : " + JSON.stringify(stakingInfo.addresses.map((x) => { return this.getShortAccountName(x); })));
        // console.log("          - uints         : " + JSON.stringify(stakingInfo.uints.map((x) => { return x.toString(); })));
        // console.log("          - strings       : " + JSON.stringify([stakingInfo.string0, stakingInfo.string1, stakingInfo.string2, stakingInfo.string3]));
        // console.log("          - accountsLength  : " + accountsLength);
        // console.log("          - totalSupply   : " + new BigNumber(totalSupply.toString()).shiftedBy(-18));
        // console.log("          - weightedEnd   : " + weightedEnd);
        // console.log("          - slashingFactor: " + new BigNumber(slashingFactor.toString()).shiftedBy(-16) + "%");
        // for (let k = 0; k < accountsLength; k++) {
        //   const stake = await staking.getStakeByIndex(k);
        //   console.log("            - stake " + k + " owner: " + stake.tokenOwner + ", duration: " + stake.stake_.duration.toString() + ", end: " + stake.stake_.end.toString() + ", index: " + stake.stake_.index.toString() + ", tokens: " + new BigNumber(stake.stake_.balance.toString()).shiftedBy(-18));
        // }
      }
    }
    console.log("        ");
  }
}

/* Exporting the module */
module.exports = {
    ZERO_ADDRESS,
    SECONDS_PER_DAY,
    SECONDS_PER_YEAR,
    Data
}

/*
// if (this.stakingFactory != null) {
//   console.log("        StakingFactory " + this.getShortAccountName(this.stakingFactory.address) + " @ " + this.stakingFactory.address);
//   const [stakingTemplate, ogToken, stakingsLength] = await Promise.all([this.stakingFactory.stakingTemplate(), this.stakingFactory.ogToken(), this.stakingFactory.stakingsLength()]);
//   console.log("        - stakingTemplate        : " + this.getShortAccountName(stakingTemplate));
//   console.log("        - ogToken                : " + this.getShortAccountName(ogToken));
//   console.log("        - stakingsLength         : " + stakingsLength);
//   const Staking = await ethers.getContractFactory("Staking");
//   for (let j = 0; j < stakingsLength; j++) {
//     const stakingAddress = await this.stakingFactory.getStakingByIndex(j);
//     const staking = Staking.attach(stakingAddress[1]);
//     const [stakingInfo, owner, accountsLength, totalSupply, weightedEnd, slashingFactor] = await Promise.all([staking.getStakingInfo(), staking.owner(), staking.accountsLength(), staking.totalSupply(), staking.weightedEnd(), staking.slashingFactor()]);
//     console.log("          - staking " + j + " @ " + this.getShortAccountName(stakingAddress[1]) + ", owner: " + this.getShortAccountName(owner));
//     // console.log("          - dataType      : " + stakingInfo.dataType  .toString());
//     // console.log("          - addresses     : " + JSON.stringify(stakingInfo.addresses.map((x) => { return this.getShortAccountName(x); })));
//     // console.log("          - uints         : " + JSON.stringify(stakingInfo.uints.map((x) => { return x.toString(); })));
//     // console.log("          - strings       : " + JSON.stringify([stakingInfo.string0, stakingInfo.string1, stakingInfo.string2, stakingInfo.string3]));
//     // console.log("          - accountsLength  : " + accountsLength);
//     // console.log("          - totalSupply   : " + new BigNumber(totalSupply.toString()).shiftedBy(-18));
//     // console.log("          - weightedEnd   : " + weightedEnd);
//     // console.log("          - slashingFactor: " + new BigNumber(slashingFactor.toString()).shiftedBy(-16) + "%");
//     // for (let k = 0; k < accountsLength; k++) {
//     //   const stake = await staking.getStakeByIndex(k);
//     //   console.log("            - stake " + k + " owner: " + stake.tokenOwner + ", duration: " + stake.stake_.duration.toString() + ", end: " + stake.stake_.end.toString() + ", index: " + stake.stake_.index.toString() + ", tokens: " + new BigNumber(stake.stake_.balance.toString()).shiftedBy(-18));
//     // }
//   }
// }

// if (this.optinoGov != null) {
//   console.log("        OptinoGov " + this.getShortAccountName(this.optinoGov.address) + " @ " + this.optinoGov.address);
//   let [ogToken, ogdToken, maxDuration, rewardsPerSecond, rewardsPerYear, collectRewardForFee, collectRewardForDelay, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.maxDuration(), this.optinoGov.rewardsPerSecond(), this.optinoGov.rewardsPerYear(), this.optinoGov.collectRewardForFee(), this.optinoGov.collectRewardForDelay(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
//   let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, rewardPool, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.rewardPool(), this.optinoGov.totalVotes()]);
//   let [proposalCount, stakeInfoLength] = await Promise.all([this.optinoGov.proposalCount(), this.optinoGov.stakeInfoLength()]);
//   console.log("        - ogToken              : " + this.getShortAccountName(ogToken));
//   console.log("        - ogdToken             : " + this.getShortAccountName(ogdToken));
//   let decimals = 18;
//   console.log("        - maxDuration          : " + maxDuration + " seconds = " + maxDuration.div(60 * 60 * 24) + " days");
//   console.log("        - rewardsPerSecond     : " + rewardsPerSecond + " = " + ethers.utils.formatUnits(rewardsPerSecond, 18) + " = " + ethers.utils.formatUnits(rewardsPerSecond.mul(60 * 60 * 24), decimals) + " per day");
//   console.log("        - collectRewardForFee  : " + collectRewardForFee + " = " + ethers.utils.formatUnits(collectRewardForFee, 16) + "%");
//   console.log("        - collectRewardForDelay: " + collectRewardForDelay + " seconds = " + collectRewardForDelay.div(60 * 60 * 24) + " days");
//   console.log("        - proposalCost         : " + proposalCost + " = " + ethers.utils.formatUnits(proposalCost, decimals));
//   console.log("        - proposalThreshold    : " + proposalThreshold + " = " + ethers.utils.formatUnits(proposalThreshold, 16) + "%");
//   console.log("        - quorum               : " + quorum + " = " + ethers.utils.formatUnits(quorum, 16) + "%");
//   console.log("        - quorumDecayPerSecond : " + quorumDecayPerSecond + " = " + ethers.utils.formatUnits(quorumDecayPerSecond.mul(60 * 60 * 24 * 365), 16) + "% per year");
//   console.log("        - votingDuration       : " + votingDuration + " seconds = " + votingDuration.div(60 * 60 * 24) + " days");
//   console.log("        - executeDelay         : " + executeDelay + " seconds = " + executeDelay.div(60 * 60 * 24) + " days");
//   console.log("        - rewardPool           : " + rewardPool + " = " + ethers.utils.formatUnits(rewardPool, decimals));
//   console.log("        - totalVotes           : " + totalVotes + " = " + ethers.utils.formatUnits(totalVotes, decimals));
//   console.log("        - rewardsPerYear       : " + ethers.utils.formatUnits(rewardsPerYear, 16) + "% compounding daily/simple partial end, rewardsPerSecond: " + ethers.utils.formatUnits(rewardsPerYear.div(60*60*24*365), 16) + "%");
//   console.log("        - proposalCount        : " + proposalCount);
//   // console.log("        - stakeInfoLength      : " + stakeInfoLength);
//
//   for (let j = 1; j < this.accounts.length && j < 4; j++) {
//     let accountAddress = this.accounts[j];
//     const _account = await this.optinoGov.accounts(accountAddress);
//     if (_account != null) {
//       console.log("        - _account           : " + j + " " + this.getShortAccountName(accountAddress) +
//         " duration: " + _account.duration +
//         ", end: " + _account.end +
//         ", tokens: " + ethers.utils.formatUnits(_account.balance, 18) +
//         ", votes: " + ethers.utils.formatUnits(_account.votes, 18) +
//         // ", staked: " + new BigNumber(_account.staked.toString()).shiftedBy(-18) +
//         ", delegatedVotes: " + ethers.utils.formatUnits(_account.delegatedVotes, 18) +
//         ", delegatee: " + this.getShortAccountName(_account.delegatee));
//     }
//   }
//
//
//   // console.log("        gov.totalVotes=" + contract.totalVotes.call().shift(-18));
//   // var proposalCount = contract.proposalCount.call();
//   // console.log("        gov.proposalCount=" + proposalCount);
//   // for (var proposalId = 1; proposalId <= proposalCount; proposalId++) {
//   //   var proposal = contract.proposals.call(proposalId);
//   //   console.log("        gov.proposals[" + proposalId + "] =" + JSON.stringify(proposal));
//   // }
//   //
//   // var stakeInfoLength = contract.stakeInfoLength.call();
//   // for (var stakeInfo_i = 0; stakeInfo_i < stakeInfoLength; stakeInfo_i++) {
//   //   var stakeInfoKey = contract.stakeInfoIndex.call(stakeInfo_i);
//   //   var stakeInfo = contract.getStakeInfoByKey.call(stakeInfoKey);
//   //   console.log("        gov.getStakeInfoByKey[" + stakeInfoKey + "] =" + JSON.stringify(stakeInfo));
//   // }
// }

// await ethers.provider.getBlockNumber().then((blockNumber) => {
//   console.log("Current block number: " + blockNumber);
// });

// await tokenContract.filters.Transfer(ZERO_ADDRESS, (data) => {
//   console.log("Transfer: " + util.inspect(data));
// });
// const iface = new ethers.utils.Interface(tokenContract.interface.abi);
// console.log("tokenContract.interface: " + util.inspect(tokenContract.interface));

// let x = tokenContract.filters.Transfer(ZERO_ADDRESS);
// console.log("        * Transfer: " + JSON.stringify(x));

// tokenContract.filters.forEach((x) => {
//   console.log("x: " + x);
// });


// provider.getTransactionReceipt(transactionHash).then(receipt => {
//   const logs = receipt.logs.filter(log => topics.some(t => t === log.topics[0]));
//   console.log('Printing array of events:');
//   const events = logs.map((log) => {
//     return iface.parseLog(log);
//   });
//   console.log(events);
// });
*/
