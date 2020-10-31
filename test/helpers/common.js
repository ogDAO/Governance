const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const BigNumber = require('bignumber.js');
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
    this.fee0Token = null;
    this.fee1Token = null;
    this.fee2Token = null;
    this.optinoGov = null;
    this.stakingFactory = null;

    this.ethUsd = new BigNumber("385.67");
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

  async setOptinoGovData(ogToken, ogdToken, fee0Token, optinoGov) {
    this.ogToken = ogToken;
    this.ogdToken = ogdToken;
    this.fee0Token = fee0Token;
    this.optinoGov = optinoGov;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.optinoGov.address, "OptinoGov");

    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.fee0Token, "Fee0Token");
    this.addContract(this.optinoGov, "OptinoGov");

    this.tokenContracts = [ogToken, ogdToken, fee0Token];
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

  async setStakingFactoryData(ogToken, fee0Token, stakingFactory) {
    this.ogToken = ogToken;
    this.fee0Token = fee0Token;
    this.stakingFactory = stakingFactory;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.stakingFactory.address, "StakingFactory");
    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.fee0Token, "Fee0Token");
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
    var o = new BigNumber(s).shiftedBy(-decimals).toFixed(decimals);
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
          if (a.name == 'tokens' || a.name == 'amount' || a.name == 'balance' || a.name == 'votes' || a.name == 'reward' || a.name == 'rewardPool' || a.name == 'totalVotes' || a.name == 'tokensBurnt' || a.name == 'tokensWithSlashingFactor') {
            // TODO Get decimals from token contracts, and only convert for token contract values
            result = result + new BigNumber(data.args[a.name].toString()).shiftedBy(-18);
          } else if (a.name == 'slashingFactor') {
            result = result + new BigNumber(data.args[a.name].toString()).shiftedBy(-16) + "%";
          } else {
            result = result + new BigNumber(data.args[a.name].toString()).toFixed(0); //.shiftedBy(-18);
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
    var fee = new BigNumber(receipt.gasUsed.toString()).multipliedBy(tx.gasPrice.toString()).shiftedBy(-18);
    var feeUsd = fee.multipliedBy(this.ethUsd);
    console.log("        " + message + " - gasUsed: " + receipt.gasUsed.toString() + ", fee: " + fee + ", feeUsd: " + feeUsd + ", @ " + new BigNumber(tx.gasPrice.toString()).shiftedBy(-9).toString() + " gwei & " + this.ethUsd + " ETH/USD, " + tx.hash);
    receipt.logs.forEach((log) => {
      this.printEvent(log);
    });
  }

  async printBalances() {
    const blockNumber = await ethers.provider.getBlockNumber();
    // let i;
    const totalTokenBalances = [new BigNumber(0), new BigNumber(0), new BigNumber(0), new BigNumber(0)];
    console.log("        ");
    console.log("         # Account                                             EtherBalanceChange               " + this.padLeft(this.symbols[0] || "???", 16) +  "               " + this.padLeft(this.symbols[1] || "???", 16) + " Blocks " + this.baseBlock.toString() + " to " + blockNumber.toString());
    if (this.tokenContracts.length > 2) {
      console.log("                                                                                                " + this.padLeft(this.symbols[2] || "???", 16) +  "               " + this.padLeft(this.symbols[3] || "???", 16));
    }
    console.log("        -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    for (let i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = (await ethers.provider.getBalance(account, this.baseBlock)).toString();
      let etherBalance = (await ethers.provider.getBalance(account, blockNumber)).toString();
      let etherBalanceDiff = new BigNumber(etherBalance).minus(new BigNumber(etherBalanceBaseBlock));
      let tokenBalances = [new BigNumber(0), new BigNumber(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = new BigNumber((await this.tokenContracts[j].balanceOf(account)).toString());
        totalTokenBalances[j] = totalTokenBalances[j].plus(tokenBalances[j]);
      }
      console.log("         " + this.padLeft(i, 2) + " " + account + " " + this.padToken(etherBalanceDiff, 18) + "    " + this.padToken(tokenBalances[0] || new BigNumber(0), this.decimals[0] || 18) + "    " + this.padToken(tokenBalances[1] || new BigNumber(0), this.decimals[1] || 18) + " " + this.getShortAccountName(account));
      if (this.tokenContracts.length > 2) {
        console.log("                                                                                     " + this.padToken(tokenBalances[2] || new BigNumber(0), this.decimals[2] || 18) + "    " + this.padToken(tokenBalances[3] || new BigNumber(0), this.decimals[3] || 18));
      }
    }
    console.log("        -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("                                                                                     " + this.padToken(totalTokenBalances[0], this.decimals[0] || 18) + "    " + this.padToken(totalTokenBalances[1], this.decimals[1] || 18) + " Total Token Balances");
    if (this.tokenContracts.length > 2) {
      console.log("                                                                                     " + this.padToken(totalTokenBalances[2], this.decimals[2] || 18) + "    " + this.padToken(totalTokenBalances[3], this.decimals[3] || 18));
    }
    console.log("        -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("        ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      let [symbol, name, decimals, totalSupply, owner] = await Promise.all([tokenContract.symbol(), tokenContract.name(), tokenContract.decimals(), tokenContract.totalSupply(), tokenContract.owner()]);
      console.log("        Token " + i + " symbol: '" + symbol + "', name: '" + name + "', decimals: " + decimals + ", totalSupply: " + new BigNumber(totalSupply.toString()).shiftedBy(-decimals) + ", owner: " + this.getShortAccountName(owner) + ", address: " + this.getShortAccountName(tokenContract.address));
      if (symbol == "OGD") {
        const dividendTokensLength = parseInt(await tokenContract.dividendTokensLength());
        console.log("        - dividendTokensLength : " + dividendTokensLength);
        for (let j = 0; j < dividendTokensLength; j++) {
          const dividendToken = await tokenContract.getDividendTokenByIndex(j);
          const unclaimedDividends = await tokenContract.unclaimedDividends(dividendToken[0]);
          console.log("        - dividendToken        : " + j + " " + this.getShortAccountName(dividendToken[0]) + ", enabled: " + dividendToken[1].toString() + ", unclaimedDividends: " + new BigNumber(unclaimedDividends.toString()).shiftedBy(-18));
        }
        for (let j = 1; j < this.accounts.length; j++) {
          let account = this.accounts[j];
          let accountName = this.getShortAccountName(account);
          if (!accountName.startsWith("Fee") && !accountName.startsWith("OG")) {
            const dividendsOwing = await tokenContract.dividendsOwing(account);
            let result = "";
            let tokenList = dividendsOwing[0];
            let owingList = dividendsOwing[1];
            let newOwingList = dividendsOwing[2];
            let separator = "";
            for (let k = 0; k < dividendTokensLength; k++) {
              result = result + separator + new BigNumber(owingList[k].toString()).shiftedBy(-18) + ", " + new BigNumber(newOwingList[k].toString()).shiftedBy(-18) + " " + this.getShortAccountName(tokenList[k]);
              separator = "; ";
            }
            console.log("        - dividendsOwing,new   : " + j + " " + this.padRight(this.getShortAccountName(account), 18) + " " + result);
          }
        }
      } else if (symbol.startsWith("OGS")) {
        const [stakingInfo, owner, accountsLength, rewardsPerYear, weightedEnd, weightedEndNumerator, weightedDurationDenominator, slashingFactor] = await Promise.all([tokenContract.getStakingInfo(), tokenContract.owner(), tokenContract.accountsLength(), tokenContract.rewardsPerYear(), tokenContract.weightedEnd(), tokenContract.weightedEndNumerator(), tokenContract.weightedDurationDenominator(), tokenContract.slashingFactor()]);
        console.log("        - staking @ " + this.getShortAccountName(tokenContract.address) + ", owner: " + this.getShortAccountName(owner));
        console.log("          - dataType                   : " + stakingInfo.dataType  .toString());
        console.log("          - addresses                  : " + JSON.stringify(stakingInfo.addresses.map((x) => { return this.getShortAccountName(x); })));
        console.log("          - uints                      : " + JSON.stringify(stakingInfo.uints.map((x) => { return x.toString(); })));
        console.log("          - strings                    : " + JSON.stringify([stakingInfo.string0, stakingInfo.string1, stakingInfo.string2, stakingInfo.string3]));
        console.log("          - rewardsPerYear             : " + new BigNumber(rewardsPerYear.toString()).shiftedBy(-16) + "%, rewardsPerSecond: " + new BigNumber(rewardsPerYear.toString()).dividedBy(60*60*24*365).shiftedBy(-16).toFixed(16) + "%");
        console.log("          - weightedDurationDenominator: " + new BigNumber(weightedDurationDenominator.toString()).shiftedBy(-18));
        console.log("          - weightedEnd                : " + weightedEnd + " = " + weightedEndNumerator + "/" + new BigNumber(totalSupply.toString()).shiftedBy(-decimals));
        console.log("          - slashingFactor             : " + new BigNumber(slashingFactor.toString()).shiftedBy(-16) + "%");
        console.log("          - accountsLength             : " + accountsLength);
        for (let k = 0; k < accountsLength; k++) {
          const account = await tokenContract.getAccountByIndex(k);
          console.log("            - account " + k + " owner: " + this.getShortAccountName(account.tokenOwner) + ", duration: " + account.account.duration.toString() + ", end: " + account.account.end.toString() + ", index: " + account.account.index.toString() + ", tokens: " + new BigNumber(account.account.balance.toString()).shiftedBy(-18));
        }
      }
    }

    if (this.stakingFactory != null) {
      console.log("        StakingFactory " + this.getShortAccountName(this.stakingFactory.address) + " @ " + this.stakingFactory.address);
      const [stakingTemplate, ogToken, stakingsLength] = await Promise.all([this.stakingFactory.stakingTemplate(), this.stakingFactory.ogToken(), this.stakingFactory.stakingsLength()]);
      console.log("        - stakingTemplate        : " + this.getShortAccountName(stakingTemplate));
      console.log("        - ogToken                : " + this.getShortAccountName(ogToken));
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

    if (this.optinoGov != null) {
      console.log("        OptinoGov " + this.getShortAccountName(this.optinoGov.address) + " @ " + this.optinoGov.address);
      let [ogToken, ogdToken, maxDuration, rewardsPerSecond, collectRewardForFee, collectRewardForDelay, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.maxDuration(), this.optinoGov.rewardsPerSecond(), this.optinoGov.collectRewardForFee(), this.optinoGov.collectRewardForDelay(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
      let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, rewardPool, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.rewardPool(), this.optinoGov.totalVotes()]);
      let [proposalCount /*, stakeInfoLength*/] = await Promise.all([this.optinoGov.proposalCount()/*, this.optinoGov.stakeInfoLength()*/]);
      console.log("        - ogToken              : " + this.getShortAccountName(ogToken));
      console.log("        - ogdToken             : " + this.getShortAccountName(ogdToken));
      let decimals = 18;
      console.log("        - maxDuration          : " + maxDuration + " seconds = " + new BigNumber(maxDuration.toString()).dividedBy(60 * 60 * 24) + " days");
      console.log("        - rewardsPerSecond     : " + rewardsPerSecond + " = " + new BigNumber(rewardsPerSecond.toString()).shiftedBy(-18) + " = " + new BigNumber(rewardsPerSecond.toString()).multipliedBy(60 * 60 * 24).shiftedBy(-decimals) + " per day");
      console.log("        - collectRewardForFee  : " + collectRewardForFee + " = " + new BigNumber(collectRewardForFee.toString()).shiftedBy(-16) + "%");
      console.log("        - collectRewardForDelay: " + collectRewardForDelay + " seconds = " + new BigNumber(collectRewardForDelay.toString()).dividedBy(60 * 60 * 24) + " days");
      console.log("        - proposalCost         : " + proposalCost + " = " + new BigNumber(proposalCost.toString()).shiftedBy(-decimals));
      console.log("        - proposalThreshold    : " + proposalThreshold + " = " + new BigNumber(proposalThreshold.toString()).shiftedBy(-16) + "%");
      console.log("        - quorum               : " + quorum + " = " + new BigNumber(quorum.toString()).shiftedBy(-16) + "%");
      console.log("        - quorumDecayPerSecond : " + quorumDecayPerSecond + " = " + new BigNumber(quorumDecayPerSecond.toString()).multipliedBy(60 * 60 * 24 * 365).shiftedBy(-16) + "% per year");
      console.log("        - votingDuration       : " + votingDuration + " seconds = " + new BigNumber(votingDuration.toString()).dividedBy(60 * 60 * 24) + " days");
      console.log("        - executeDelay         : " + executeDelay + " seconds = " + new BigNumber(executeDelay.toString()).dividedBy(60 * 60 * 24) + " days");
      console.log("        - rewardPool           : " + rewardPool + " = " + new BigNumber(rewardPool.toString()).shiftedBy(-decimals));
      console.log("        - totalVotes           : " + totalVotes + " = " + new BigNumber(totalVotes.toString()).shiftedBy(-decimals));
      console.log("        - proposalCount        : " + proposalCount);
      // console.log("        - stakeInfoLength      : " + stakeInfoLength);

      for (let j = 1; j < this.accounts.length && j < 4; j++) {
        let account = this.accounts[j];
        const commitment = await this.optinoGov.commitments(account);
        if (commitment != null) {
          console.log("        - commitment           : " + j + " " + this.getShortAccountName(account) +
            " duration: " + commitment.duration +
            ", end: " + commitment.end +
            ", tokens: " + new BigNumber(commitment.tokens.toString()).shiftedBy(-18) +
            ", votes: " + new BigNumber(commitment.votes.toString()).shiftedBy(-18) +
            ", staked: " + new BigNumber(commitment.staked.toString()).shiftedBy(-18) +
            ", delegatedVotes: " + new BigNumber(commitment.delegatedVotes.toString()).shiftedBy(-18) +
            ", delegatee: " + this.getShortAccountName(commitment.delegatee));
        }
      }


      // console.log("        gov.totalVotes=" + contract.totalVotes.call().shift(-18));
      // var proposalCount = contract.proposalCount.call();
      // console.log("        gov.proposalCount=" + proposalCount);
      // for (var proposalId = 1; proposalId <= proposalCount; proposalId++) {
      //   var proposal = contract.proposals.call(proposalId);
      //   console.log("        gov.proposals[" + proposalId + "] =" + JSON.stringify(proposal));
      // }
      //
      // var stakeInfoLength = contract.stakeInfoLength.call();
      // for (var stakeInfo_i = 0; stakeInfo_i < stakeInfoLength; stakeInfo_i++) {
      //   var stakeInfoKey = contract.stakeInfoIndex.call(stakeInfo_i);
      //   var stakeInfo = contract.getStakeInfoByKey.call(stakeInfoKey);
      //   console.log("        gov.getStakeInfoByKey[" + stakeInfoKey + "] =" + JSON.stringify(stakeInfo));
      // }
    }

    console.log("        ");
  }
}

/* Exporting the module */
module.exports = {
    ZERO_ADDRESS,
    Data
}

/*
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
