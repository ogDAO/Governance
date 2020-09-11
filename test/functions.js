// 26 Apr 2020 21:11 AEDT ETH/USD from CMC and ethgasstation.info normal
var ethPriceUSD = 435.85;
var defaultGasPrice = web3.toWei("28.1", "gwei");

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var NULLACCOUNT = "0x0000000000000000000000000000000000000000";
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "miner");
addAccount(eth.accounts[1], "deployer");
addAccount(eth.accounts[2], "user1");
addAccount(eth.accounts[3], "user2");
addAccount(eth.accounts[4], "user3");
addAccount(eth.accounts[5], "user4");
addAccount(NULLACCOUNT, "null");

var miner = eth.accounts[0];
var deployer = eth.accounts[1];
var user1 = eth.accounts[2];
var user2 = eth.accounts[3];
var user3 = eth.accounts[4];
var user4 = eth.accounts[5];

console.log("DATA: var miner=\"" + eth.accounts[0] + "\";");
console.log("DATA: var deployer=\"" + eth.accounts[1] + "\";");
console.log("DATA: var user1=\"" + eth.accounts[2] + "\";");
console.log("DATA: var user2=\"" + eth.accounts[3] + "\";");
console.log("DATA: var user3=\"" + eth.accounts[4] + "\";");
console.log("DATA: var user4=\"" + eth.accounts[5] + "\";");

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length && i < accounts.length; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
    if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
      personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
    }
  }
  while (txpool.status.pending > 0) {
  }
  baseBlock = eth.blockNumber;
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
  addAddressNames(account, accountName);
}

addAddressNames(NULLACCOUNT, "null");

// -----------------------------------------------------------------------------
// Token Contract
// -----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Token Contracts
//-----------------------------------------------------------------------------
var _tokenContractAddresses = [];
var _tokenContractAbis = [];
var _tokens = [null, null, null, null];
var _symbols = ["0", "(unused)", "2", "3"];
var _decimals = [18, 18, 18, 18];

function addTokenContractAddressAndAbi(i, address, abi) {
  _tokenContractAddresses[i] = address;
  _tokenContractAbis[i] = abi;
  _tokens[i] = web3.eth.contract(abi).at(address);
  // if (i == 0) {
  //   _symbols[i] = "WETH";
  //   _decimals[i] = 18;
  // } else {
    _symbols[i] = _tokens[i].symbol.call();
    _decimals[i] = _tokens[i].decimals.call();
  // }
}


//-----------------------------------------------------------------------------
//Account ETH and token balances
//-----------------------------------------------------------------------------
function printBalances() {
  var i = 0;
  var j;
  var totalTokenBalances = [new BigNumber(0), new BigNumber(0), new BigNumber(0), new BigNumber(0)];
  console.log("RESULT:  # Account                                             EtherBalanceChange               " + padLeft(_symbols[0], 16) + "               " + padLeft(_symbols[1], 16) + " Name");
  // console.log("RESULT:                                                                                         " + padLeft(_symbols[2], 16) + "               " + padLeft(_symbols[3], 16));
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenBalances = [];
    for (j = 0; j < 2; j++) {
      tokenBalances[j] = _tokens[j] == null ? new BigNumber(0) : _tokens[j].balanceOf.call(e).shift(-_decimals[j]);
      totalTokenBalances[j] = totalTokenBalances[j].add(tokenBalances[j]);
    }
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " +
      padToken(tokenBalances[0], _decimals[0]) + " " + padToken(tokenBalances[1], _decimals[1]) + " " + accountNames[e]);
    // console.log("RESULT:                                                                           " +
    //   padToken(tokenBalances[2], _decimals[2]) + " " + padToken(tokenBalances[3], _decimals[3]));
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenBalances[0], _decimals[0]) + " " + padToken(totalTokenBalances[1], _decimals[1]) + " Total Token Balances");
  // console.log("RESULT:                                                                           " + padToken(totalTokenBalances[2], _decimals[2]) + " " + padToken(totalTokenBalances[3], _decimals[3]));
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  while (o.length < 30) {
    o = o + " ";
  }
  return o;
}

function padLeft(s, n) {
  var o = s;
  while (o.length < n) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  var block = eth.getBlock(txReceipt.blockNumber);
  console.log("RESULT: " + name + " status=" + txReceipt.status + (txReceipt.status == 0 ? " Failure" : " Success") + " gas=" + tx.gas +
    " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH + " costUSD=" + gasCostUSD +
    " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + web3.fromWei(gasPrice, "gwei") + " gwei block=" +
    txReceipt.blockNumber + " txIx=" + tx.transactionIndex + " txId=" + txId +
    " @ " + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());
  if (txReceipt.status == 0) {
    var trace = debug.traceTransaction(txId);
    var memory = trace.structLogs[trace.structLogs.length-1].memory;
    for (var i = memory.length - 10; i < memory.length; i++) {
      console.log("RESULT: debug.traceTransaction().trace.structLogs[" + (trace.structLogs.length-1) + "].memory[" + i + "]" +
        memory[i] + " => '" + web3.toAscii(memory[i]) + "'");
    }
  }
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function failIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 0) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 1) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
// Wait one block
//-----------------------------------------------------------------------------
function waitOneBlock(oldCurrentBlock) {
  while (eth.blockNumber <= oldCurrentBlock) {
  }
  console.log("RESULT: Waited one block");
  console.log("RESULT: ");
  return eth.blockNumber;
}


//-----------------------------------------------------------------------------
// Pause for {x} seconds
//-----------------------------------------------------------------------------
function pause(message, addSeconds) {
  var time = new Date((parseInt(new Date().getTime()/1000) + addSeconds) * 1000);
  console.log("RESULT: Pausing '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Paused '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some unixTime + additional seconds
//-----------------------------------------------------------------------------
function waitUntil(message, unixTime, addSeconds) {
  var t = parseInt(unixTime) + parseInt(addSeconds) + parseInt(1);
  var time = new Date(t * 1000);
  console.log("RESULT: Waiting until '" + message + "' at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Waited until '" + message + "' at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some block
//-----------------------------------------------------------------------------
function waitUntilBlock(message, block, addBlocks) {
  var b = parseInt(block) + parseInt(addBlocks) + parseInt(1);
  console.log("RESULT: Waiting until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  while (eth.blockNumber <= b) {
  }
  console.log("RESULT: Waited until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
// Convert array of BigNumbers by shifting decimals
//-----------------------------------------------------------------------------
function shiftBigNumberArray(data, decimals) {
  var results = [];
  // console.log("data: " + JSON.stringify(data));
  data.forEach(function(d) {results.push(d.shift(decimals).toString());});
  // console.log("results: " + JSON.stringify(results));
  return results;
}


//-----------------------------------------------------------------------------
// Token Contract A
//-----------------------------------------------------------------------------
var tokenFromBlock = [0, 0, 0, 0];
function printTokenContractDetails(j) {
  if (tokenFromBlock[j] == 0) {
    tokenFromBlock[j] = baseBlock;
  }
  console.log("RESULT: token" + j + "ContractAddress=" + getShortAddressName(_tokenContractAddresses[j]));
  if (_tokenContractAddresses[j] != null) {
    var contract = _tokens[j];
    var decimals = _decimals[j];
    try {
      console.log("RESULT: token" + j + ".owner/new=" + getShortAddressName(contract.owner.call()) + "/" + getShortAddressName(contract.newOwner.call()));
    } catch (error) {
      console.log("RESULT: token" + j + ".owner/new - Function call failed");
    }
    try {
      console.log("RESULT: token" + j + ".details='" + contract.symbol.call() + "' '" + contract.name.call() + "' " + decimals + " dp");
    } catch (error) {
      console.log("RESULT: token" + j + ".details - Function call failed");
    }
    console.log("RESULT: token" + j + ".totalSupply=" + contract.totalSupply.call().shift(-decimals));
    try {
      console.log("RESULT: token" + j + ".strike=" + contract.strike.call().shift(-decimals));
      console.log("RESULT: token" + j + ".bound=" + contract.bound.call().shift(-decimals));
    } catch (e) {
    }

    var latestBlock = eth.blockNumber;
    var i;

    if (j == 0) {
      var logInfoEvents = contract.LogInfo({}, { fromBlock: tokenFromBlock[j], toBlock: latestBlock });
      i = 0;
      logInfoEvents.watch(function (error, result) {
        console.log("RESULT: token" + j + ".LogInfo " + i++ + " #" + result.blockNumber + " " +
        " topic=" + result.args.topic +
        " number=" + result.args.number + " " + result.args.number.shift(-decimals) +
        " data=" + result.args.data +
        " note=" + result.args.note +
        " addr=" + getShortAddressName(result.args.addr));
      });
      logInfoEvents.stopWatching();

      var updateAccountInfoEvents = contract.UpdateAccountInfo({}, { fromBlock: tokenFromBlock[j], toBlock: latestBlock });
      i = 0;
      updateAccountInfoEvents.watch(function (error, result) {
        console.log("RESULT: token" + j + ".UpdateAccountInfo " + i++ + " #" + result.blockNumber + " " +
        " dividendToken=" + getShortAddressName(result.args.dividendToken) +
        " account=" + getShortAddressName(result.args.account) +
        " owing=" + result.args.owing + " " + result.args.owing.shift(-decimals) +
        " totalOwing=" + result.args.totalOwing + " " + result.args.totalOwing.shift(-decimals) +
        " lastDividendPoints=" + result.args.lastDividendPoints + " " + result.args.lastDividendPoints.shift(-decimals) +
        " totalDividendPoints=" + result.args.totalDividendPoints + " " + result.args.totalDividendPoints.shift(-decimals) +
        " unclaimedDividends=" + result.args.unclaimedDividends + " " + result.args.unclaimedDividends.shift(-decimals));
      });
      updateAccountInfoEvents.stopWatching();
    }

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenFromBlock[j], toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: token" + j + ".OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenFromBlock[j], toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      // console.log("RESULT: token" + j + ".Approval " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result));
      console.log("RESULT: token" + j + ".Approval " + i++ + " #" + result.blockNumber +
        " tokenOwner=" + getShortAddressName(result.args.tokenOwner) +
        " spender=" + getShortAddressName(result.args.spender) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenFromBlock[j], toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      // console.log("RESULT: token" + j + ".Transfer " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result));
      console.log("RESULT: token" + j + ".Transfer " + i++ + " #" + result.blockNumber +
        " from=" + getShortAddressName(result.args.from) +
        " to=" + getShortAddressName(result.args.to) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenFromBlock[j] = latestBlock + 1;
  }
}


//-----------------------------------------------------------------------------
// Factory Contract
//-----------------------------------------------------------------------------
var _factoryContractAddress = null;
var _factoryContractAbi = null;
function addFactoryContractAddressAndAbi(address, tokenAbi) {
  _factoryContractAddress = address;
  _factoryContractAbi = tokenAbi;
}

var _factoryFromBlock = 0;
function getTokenContractDeployed() {
  var addresses = [];
  console.log("RESULT: factoryContractAddress=" + _factoryContractAddress);
  if (_factoryContractAddress != null && _factoryContractAbi != null) {
    var contract = eth.contract(_factoryContractAbi).at(_factoryContractAddress);

    var latestBlock = eth.blockNumber;
    var i;

    var tokenDeployedEvents = contract.TokenDeployed({}, { fromBlock: _factoryFromBlock, toBlock: latestBlock });
    i = 0;
    tokenDeployedEvents.watch(function (error, result) {
      console.log("RESULT: get TokenDeployed " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      addresses.push(result.args.token);
    });
    tokenDeployedEvents.stopWatching();
  }
  return addresses;
}


// -----------------------------------------------------------------------------
// Feed Contract
// -----------------------------------------------------------------------------
var _govContractAddress = null;
var _govContractAbi = null;
function addGovContractAddressAndAbi(address, abi) {
  _govContractAddress = address;
  _govContractAbi = abi;
}

var _govFromBlock = 0;
function printGovContractDetails() {
  console.log("RESULT: govContractAddress=" + getShortAddressName(_govContractAddress));
  // console.log("RESULT: priceFeedContractAbi=" + JSON.stringify(_govContractAbi));
  if (_govContractAddress != null && _govContractAbi != null) {
    var contract = web3.eth.contract(_govContractAbi).at(_govContractAddress);
    console.log("RESULT: gov.token=" + getShortAddressName(contract.token.call()));
    var maxLockTerm = contract.maxLockTerm.call();
    console.log("RESULT: gov.maxLockTerm=" + maxLockTerm + " =" + maxLockTerm.div(60*60*24) + " days");
    var rewardsPerSecond = contract.rewardsPerSecond.call();
    console.log("RESULT: gov.rewardsPerSecond=" + rewardsPerSecond.shift(-18) + " /day=" + rewardsPerSecond.mul(60).mul(60).mul(24).shift(-18) + " /year=" + rewardsPerSecond.mul(60).mul(60).mul(24).mul(365).shift(-18));
    console.log("RESULT: gov.proposalCost=" + contract.proposalCost.call().shift(-18));
    console.log("RESULT: gov.proposalThreshold=" + contract.proposalThreshold.call().shift(-16) + "%");
    console.log("RESULT: gov.quorum=" + contract.quorum.call().shift(-16) + "%");
    var quorumDecayPerSecond = contract.quorumDecayPerSecond.call();
    console.log("RESULT: gov.quorumDecayPerSecond=" + quorumDecayPerSecond.shift(-16) + "%" + " /year=" + quorumDecayPerSecond.mul(60).mul(60).mul(24).mul(365).shift(-16));
    console.log("RESULT: gov.votingDuration=" + contract.votingDuration.call() + " seconds");
    console.log("RESULT: gov.executeDelay=" + contract.executeDelay.call() + " seconds");
    console.log("RESULT: gov.rewardPool=" + contract.rewardPool.call().shift(-18));
    console.log("RESULT: gov.totalVotes=" + contract.totalVotes.call().shift(-18));
    console.log("RESULT: gov.proposalCount=" + contract.proposalCount.call());

    // var users = [user1, user2, user3, user4];
    var users = [user1, user2, user3, user4];
    for (var userIndex in users) {
      var lock = contract.locks.call(users[userIndex]);
      console.log("RESULT: gov.locks[" + getShortAddressName(users[userIndex]) + "] balance=" + lock[2].shift(-18) + ", duration=" + lock[0] + ", end=" + lock[1] + " " + new Date(lock[1]*1000).toUTCString() + ", votes=" + lock[3].shift(-18).toString());
    }

    // address public xs2token;
    // uint256 public rewardsPerSecond;
    //
    // uint256 public proposalCost;
    // uint256 public proposalThreshold;
    // uint256 public quorum;
    // uint256 public votingDuration;
    // uint256 public executeDelay;
    //
    // uint256 public rewardPool;
    // uint256 public totalVotes;
    // mapping(address => Stake) public stakes; // Staked tokens per address
    //
    // uint256 public proposalCount;
    // mapping(uint256 => Proposal) public proposals;


    var latestBlock = eth.blockNumber;
    var i;

    var rewardsPerSecondUpdatedEvents = contract.RewardsPerSecondUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    rewardsPerSecondUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: RewardsPerSecondUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    rewardsPerSecondUpdatedEvents.stopWatching();

    var proposalCostUpdatedEvents = contract.ProposalCostUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    proposalCostUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: ProposalCostUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    proposalCostUpdatedEvents.stopWatching();

    var proposalThresholdUpdatedEvents = contract.ProposalThresholdUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    proposalThresholdUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: ProposalThresholdUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    proposalThresholdUpdatedEvents.stopWatching();

    var quorumUpdatedEvents = contract.QuorumUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    quorumUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: QuorumUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    quorumUpdatedEvents.stopWatching();

    var votingDurationUpdatedEvents = contract.VotingDurationUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    votingDurationUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: VotingDurationUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    votingDurationUpdatedEvents.stopWatching();

    var executeDelayUpdatedEvents = contract.ExecuteDelayUpdated({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    executeDelayUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: ExecuteDelayUpdated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    executeDelayUpdatedEvents.stopWatching();

    var lockedEvents = contract.Locked({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    lockedEvents.watch(function (error, result) {
      // console.log("RESULT: Locked " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      console.log("RESULT: Locked " + i++ + " #" + result.blockNumber +
        " user=" + getShortAddressName(result.args.user) +
        " tokens=" + result.args.tokens.shift(-18) +
        " balance=" + result.args.balance.shift(-18) +
        " duration=" + result.args.duration +
        " end=" + result.args.end + " " + new Date(result.args.end * 1000).toUTCString() +
        " votes=" + result.args.votes.shift(-18) +
        " rewardPool=" + result.args.rewardPool.shift(-18) +
        " totalVotes=" + result.args.totalVotes.shift(-18));
    });
    lockedEvents.stopWatching();

    var stakeInfoAddedEvents = contract.StakeInfoAdded({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    stakeInfoAddedEvents.watch(function (error, result) {
      console.log("RESULT: StakeInfoAdded " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    stakeInfoAddedEvents.stopWatching();

    var stakedEvents = contract.Staked({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    stakedEvents.watch(function (error, result) {
      // console.log("RESULT: Staked " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      console.log("RESULT: Staked " + i++ + " #" + result.blockNumber +
        " tokenOwner=" + getShortAddressName(result.args.tokenOwner) +
        " tokens=" + result.args.tokens.shift(-18) +
        " balance=" + result.args.balance.shift(-18) +
        " stakingKey=" + stakingKey);
    });
    stakedEvents.stopWatching();

    var unstakeEvents = contract.Unstaked({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    unstakeEvents.watch(function (error, result) {
      // console.log("RESULT: Unstaked " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      console.log("RESULT: Unstaked " + i++ + " #" + result.blockNumber +
        " tokenOwner=" + getShortAddressName(result.args.tokenOwner) +
        " tokens=" + result.args.tokens.shift(-18) +
        " balance=" + result.args.balance.shift(-18) +
        " stakingKey=" + stakingKey);
    });
    unstakeEvents.stopWatching();


    var collectedEvents = contract.Collected({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    collectedEvents.watch(function (error, result) {
      console.log("RESULT: Collected " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    collectedEvents.stopWatching();

    var unlockedEvents = contract.Unlocked({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    unlockedEvents.watch(function (error, result) {
      console.log("RESULT: Unlocked " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    unlockedEvents.stopWatching();

    var proposedEvents = contract.Proposed({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    proposedEvents.watch(function (error, result) {
      console.log("RESULT: Proposed " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    proposedEvents.stopWatching();

    var votedEvents = contract.Voted({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    votedEvents.watch(function (error, result) {
      console.log("RESULT: Voted " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    votedEvents.stopWatching();

    var executedEvents = contract.Executed({}, { fromBlock: _govFromBlock, toBlock: latestBlock });
    i = 0;
    executedEvents.watch(function (error, result) {
      console.log("RESULT: Executed " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    executedEvents.stopWatching();

    _govFromBlock = latestBlock + 1;
  }
}
