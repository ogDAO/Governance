const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const BigNumber = require('bignumber.js');
const util = require('util');

class MyData {

  constructor() {
    // console.log("    MyData.constructor()");
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

    this.ethUsd = new BigNumber("385.67");
  }

  async init() {
    const _accounts = await ethers.getSigners();
    this.owner = await _accounts[0].getAddress();
    this.user1 = await _accounts[1].getAddress();
    this.user2 = await _accounts[2].getAddress();
    this.user3 = await _accounts[3].getAddress();

    this.addAccount(this.owner, "Owner");
    this.addAccount(this.user1, "User1");
    this.addAccount(this.user2, "User2");
    this.addAccount(this.user3, "User3");

    // await ethers.provider.getBlockNumber().then((blockNumber) => {
    //   console.log("Current block number: " + blockNumber);
    // });
    this.baseBlock = await ethers.provider.getBlockNumber();
    // console.log("    MyData.init - baseBlock: " + this.baseBlock);
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account.toLowerCase()] = accountName;
    // addAddressNames(account, accountName);
    // console.log("    MyData.addAccount: " + account + " => " + accountName);
  }

  addContract(contract, contractName) {
    this.contractsByAddress[contract.address.toLowerCase()] = {
      address: contract.address,
      name: contractName,
      interface: contract.interface,
    };
    // console.log("    MyData.addContract: " + contract.address.toLowerCase() + " => " + this.contractsByAddress[contract.address.toLowerCase()]);
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
          if (a.name == 'tokens' || a.name == 'amount') {
            // TODO Get decimals from token contracts, and only convert for token contract values
            result = result + new BigNumber(data.args[a.name].toString()).shiftedBy(-18).toString();
          } else {
            result = result + new BigNumber(data.args[a.name].toString()).toFixed(0); //.shiftedBy(-18);
          }
        } else {
          result = result + data.args[a.name].toString();
        }
        separator = ", ";
      });
      result = result + ")";
      console.log("    + " + result);
    } else {
      console.log("    + " + JSON.stringify(log));
    }
  }

  async printTxData(message, tx) {
    const receipt = await tx.wait();
    var fee = new BigNumber(receipt.gasUsed.toString()).multipliedBy(tx.gasPrice.toString()).shiftedBy(-18);
    var feeUsd = fee.multipliedBy(this.ethUsd);
    console.log("    " + message + " - gasUsed: " + receipt.gasUsed.toString() + ", fee: " + fee + ", feeUsd: " + feeUsd + ", @ " + new BigNumber(tx.gasPrice.toString()).shiftedBy(-9).toString() + " gwei & " + this.ethUsd + " ETH/USD, " + tx.hash);
    receipt.logs.forEach((log) => {
      this.printEvent(log);
    });
  }

  async printBalances() {
    var blockNumber = await ethers.provider.getBlockNumber();
    var i = 0;
    var totalTokenBalances = [new BigNumber(0), new BigNumber(0), new BigNumber(0), new BigNumber(0)];
    console.log("    ");
    console.log("     # Account                                             EtherBalanceChange               " + this.padLeft(this.symbols[0] || "???", 16) +  "               " + this.padLeft(this.symbols[1] || "???", 16) + " Blocks " + this.baseBlock.toString() + " to " + blockNumber.toString());
    if (this.tokenContracts.length > 2) {
      console.log("                                                                                            " + this.padLeft(this.symbols[2] || "???", 16) +  "               " + this.padLeft(this.symbols[3] || "???", 16));
    }
    console.log("    -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
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
      console.log("     " + this.padLeft(i, 2) + " " + account + " " + this.padToken(etherBalanceDiff, 18) + "    " + this.padToken(tokenBalances[0] || new BigNumber(0), this.decimals[0] || 18) + "    " + this.padToken(tokenBalances[1] || new BigNumber(0), this.decimals[1] || 18) + " " + this.getShortAccountName(account));
      if (this.tokenContracts.length > 2) {
        console.log("                                                                                 " + this.padToken(tokenBalances[2] || new BigNumber(0), this.decimals[2] || 18) + "    " + this.padToken(tokenBalances[3] || new BigNumber(0), this.decimals[3] || 18));
      }
    }
    console.log("    -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("                                                                                 " + this.padToken(totalTokenBalances[0], this.decimals[0] || 18) + "    " + this.padToken(totalTokenBalances[1], this.decimals[1] || 18) + " Total Token Balances");
    if (this.tokenContracts.length > 2) {
      console.log("                                                                                 " + this.padToken(totalTokenBalances[2], this.decimals[2] || 18) + "    " + this.padToken(totalTokenBalances[3], this.decimals[3] || 18));
    }
    console.log("    -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
    console.log("    ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      console.log("    Token " + i + " " + this.getShortAccountName(tokenContract.address) + " @ " + tokenContract.address);
      let [symbol, name, decimals, totalSupply, owner] = await Promise.all([tokenContract.symbol(), tokenContract.name(), tokenContract.decimals(), tokenContract.totalSupply(), tokenContract.owner()]);
      console.log("    - symbol               : " + symbol);
      console.log("    - name                 : " + name);
      console.log("    - decimals             : " + decimals);
      console.log("    - totalSupply          : " + new BigNumber(totalSupply.toString()).shiftedBy(-decimals));
      console.log("    - owner                : " + this.getShortAccountName(owner));
      if (symbol == "OGD") {
        const dividendTokensLength = parseInt(await tokenContract.dividendTokensLength());
        console.log("    - dividendTokensLength : " + dividendTokensLength);
        for (let j = 0; j < dividendTokensLength; j++) {
          const dividendToken = await tokenContract.getDividendTokenByIndex(j);
          const unclaimedDividends = await tokenContract.unclaimedDividends(dividendToken[0]);
          console.log("    - dividendToken        : " + j + " " + this.getShortAccountName(dividendToken[0]) + ", enabled: " + dividendToken[1].toString() + ", unclaimedDividends: " + new BigNumber(unclaimedDividends.toString()).shiftedBy(-18).toString());
        }
        for (let j = 1; j < this.accounts.length && j < 4; j++) {
          let account = this.accounts[j];
          const dividendsOwing = await tokenContract.dividendsOwing(account);
          console.log("    - dividendsOwing       : " + j + " " + this.getShortAccountName(account));
          let tokenList = dividendsOwing[0];
          let owingList = dividendsOwing[1];
          for (let k = 0; k < dividendTokensLength; k++) {
            console.log("                               - " + this.getShortAccountName(tokenList[k]) + " " + new BigNumber(owingList[k].toString()).shiftedBy(-18).toString());
          }
        }
      }
      // await ethers.provider.getBlockNumber().then((blockNumber) => {
      //   console.log("Current block number: " + blockNumber);
      // });

      // await tokenContract.filters.Transfer(ZERO_ADDRESS, (data) => {
      //   console.log("Transfer: " + util.inspect(data));
      // });
      // const iface = new ethers.utils.Interface(tokenContract.interface.abi);
      // console.log("tokenContract.interface: " + util.inspect(tokenContract.interface));

      // let x = tokenContract.filters.Transfer(ZERO_ADDRESS);
      // console.log("    * Transfer: " + JSON.stringify(x));

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
    }

    if (this.optinoGov != null) {
      console.log("    OptinoGov " + this.getShortAccountName(this.optinoGov.address) + " @ " + this.optinoGov.address);

      let [ogToken, ogdToken, maxDuration, rewardsPerSecond, collectRewardForFee, collectRewardForDelay, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.maxDuration(), this.optinoGov.rewardsPerSecond(), this.optinoGov.collectRewardForFee(), this.optinoGov.collectRewardForDelay(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
      let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, rewardPool, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.rewardPool(), this.optinoGov.totalVotes()]);
      let [proposalCount, stakeInfoLength] = await Promise.all([this.optinoGov.proposalCount(), this.optinoGov.stakeInfoLength()]);
      console.log("    - ogToken              : " + this.getShortAccountName(ogToken));
      console.log("    - ogdToken             : " + this.getShortAccountName(ogdToken));
      let decimals = 18;
      console.log("    - maxDuration          : " + maxDuration + " seconds = " + new BigNumber(maxDuration).dividedBy(60 * 60 * 24) + " days");
      console.log("    - rewardsPerSecond     : " + rewardsPerSecond + " = " + new BigNumber(rewardsPerSecond).shiftedBy(-18) + " = " + new BigNumber(rewardsPerSecond).multipliedBy(60 * 60 * 24).shiftedBy(-decimals) + " per day");
      console.log("    - collectRewardForFee  : " + collectRewardForFee + " = " + new BigNumber(collectRewardForFee).shiftedBy(-16) + "%");
      console.log("    - collectRewardForDelay: " + collectRewardForDelay + " seconds = " + new BigNumber(collectRewardForDelay).dividedBy(60 * 60 * 24) + " days");
      console.log("    - proposalCost         : " + proposalCost + " = " + new BigNumber(proposalCost).shiftedBy(-decimals));
      console.log("    - proposalThreshold    : " + proposalThreshold + " = " + new BigNumber(proposalThreshold).shiftedBy(-16) + "%");
      console.log("    - quorum               : " + quorum + " = " + new BigNumber(quorum).shiftedBy(-16) + "%");
      console.log("    - quorumDecayPerSecond : " + quorumDecayPerSecond + " = " + new BigNumber(quorumDecayPerSecond).multipliedBy(60 * 60 * 24 * 365).shiftedBy(-16) + "% per year");
      console.log("    - votingDuration       : " + votingDuration + " seconds = " + new BigNumber(votingDuration).dividedBy(60 * 60 * 24) + " days");
      console.log("    - executeDelay         : " + executeDelay + " seconds = " + new BigNumber(executeDelay).dividedBy(60 * 60 * 24) + " days");
      console.log("    - rewardPool           : " + rewardPool + " = " + new BigNumber(rewardPool).shiftedBy(-decimals));
      console.log("    - totalVotes           : " + totalVotes + " = " + new BigNumber(totalVotes).shiftedBy(-decimals));
      console.log("    - proposalCount        : " + proposalCount);
      console.log("    - stakeInfoLength      : " + stakeInfoLength);

      for (let j = 1; j < this.accounts.length && j < 4; j++) {
        let account = this.accounts[j];
        const commitment = await this.optinoGov.commitments(account);
        if (commitment != null) {
          console.log("    - commitment           : " + j + " " + this.getShortAccountName(account) +
            " duration: " + commitment.duration +
            ", end: " + commitment.end +
            ", tokens: " + new BigNumber(commitment.tokens).shiftedBy(-18) +
            ", votes: " + new BigNumber(commitment.votes).shiftedBy(-18) +
            ", staked: " + new BigNumber(commitment.staked).shiftedBy(-18) +
            ", delegatedVotes: " + new BigNumber(commitment.delegatedVotes).shiftedBy(-18) +
            ", delegatee: " + this.getShortAccountName(commitment.delegatee));

          // struct Commitment {
          //     uint128 duration;
          //     uint128 end;
          //     uint tokens;
          //     uint staked;
          //     uint votes;
          //     uint delegatedVotes;
          //     address delegatee;
          // }

          // console.log("    - commitment           : " + j + " " + this.getShortAccountName(account) + " " + JSON.stringify(commitment));
        }

        // uint term;
        // uint end;
        // uint tokens;
        // uint votes;
        // uint staked;
        // mapping(bytes32 => uint) stakes;

        // let tokenList = dividendsOwing[0];
        // let owingList = dividendsOwing[1];
        // for (let k = 0; k < dividendTokensLength; k++) {
        //   console.log("                               - " + this.getShortAccountName(tokenList[k]) + " " + owingList[k] + " = " + new BigNumber(owingList[k]).shiftedBy(-18).toFixed(18));
        // }
      }


      // console.log("    gov.totalVotes=" + contract.totalVotes.call().shift(-18));
      // var proposalCount = contract.proposalCount.call();
      // console.log("    gov.proposalCount=" + proposalCount);
      // for (var proposalId = 1; proposalId <= proposalCount; proposalId++) {
      //   var proposal = contract.proposals.call(proposalId);
      //   console.log("    gov.proposals[" + proposalId + "] =" + JSON.stringify(proposal));
      // }
      //
      // var stakeInfoLength = contract.stakeInfoLength.call();
      // for (var stakeInfo_i = 0; stakeInfo_i < stakeInfoLength; stakeInfo_i++) {
      //   var stakeInfoKey = contract.stakeInfoIndex.call(stakeInfo_i);
      //   var stakeInfo = contract.getStakeInfoByKey.call(stakeInfoKey);
      //   console.log("    gov.getStakeInfoByKey[" + stakeInfoKey + "] =" + JSON.stringify(stakeInfo));
      // }
    }

    console.log("    ");
  }
}

/* Exporting the module */
module.exports = {
    ZERO_ADDRESS,
    MyData
}
