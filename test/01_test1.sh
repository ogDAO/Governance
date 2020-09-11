#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019. The GPLv2 Licence.
# ----------------------------------------------------------------------------------------------

# echo "Options: [full|takerSell|takerBuy|exchange]"

MODE=${1:-full}

source settings
echo "---------- Settings ----------" | tee $TEST1OUTPUT
cat ./settings | tee -a $TEST1OUTPUT
echo "" | tee -a $TEST1OUTPUT

CURRENTTIME=`date +%s`
CURRENTTIMES=`perl -le "print scalar localtime $CURRENTTIME"`
START_DATE=`echo "$CURRENTTIME+45" | bc`
START_DATE_S=`perl -le "print scalar localtime $START_DATE"`
END_DATE=`echo "$CURRENTTIME+60*2" | bc`
END_DATE_S=`perl -le "print scalar localtime $END_DATE"`

printf "CURRENTTIME = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE  = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE    = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file ---
# cp $SOURCEDIR/$WETH9SOL .
# cp $SOURCEDIR/$DAISOL .
rsync -rp $SOURCEDIR/*.sol . --exclude=Multisig.sol --exclude=test/ # */
# rsync -rp $SOURCEDIR/* . --exclude=Multisig.sol # */
# Copy modified contracts if any files exist
# find ./modifiedContracts -type f -name \* -exec cp {} . \;

# --- Modify parameters ---
`perl -pi -e "s/365 days/10000/" $GOVSOL`
`perl -pi -e "s/external onlySelf/external/" $GOVSOL`

# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$MINTABLETOKENSOL --outputsol=$TESTTOKENFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$MAKERDAOFEEDSOL --outputsol=$MAKERDAOFEEDFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$FEEDADAPTORSOL --outputsol=$FEEDADAPTORFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$OPTINOFACTORYSOL --outputsol=$OPTINOFACTORYFLATTENED --verbose | tee -a $TEST1OUTPUT


DIFFS1=`diff -r -x '*.js' -x '*.json' -x '*.txt' -x 'testchain' -x '*.md' -x '*.sh' -x 'settings' -x 'modifiedContracts' $SOURCEDIR .`
echo "--- Differences $SOURCEDIR/*.sol *.sol ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.7.1 --version | tee -a $TEST1OUTPUT

echo "var ogTokenOutput=`solc_0.7.1 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $OGTOKENSOL`;" > $OGTOKENJS
echo "var govOutput=`solc_0.7.1 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $GOVSOL`;" > $GOVJS
echo "var testTokenOutput=`solc_0.7.1 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $TESTTOKENSOL`;" > $TESTTOKENJS

if [ "$MODE" = "compile" ]; then
  echo "Compiling only"
  exit 1;
fi


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$OGTOKENJS");
loadScript("$GOVJS");
loadScript("$TESTTOKENJS");
loadScript("lookups.js");
loadScript("functions.js");

var ogTokenAbi = JSON.parse(ogTokenOutput.contracts["$OGTOKENSOL:$OGTOKENNAME"].abi);
var ogTokenBin = "0x" + ogTokenOutput.contracts["$OGTOKENSOL:$OGTOKENNAME"].bin;
var govAbi = JSON.parse(govOutput.contracts["$GOVSOL:$GOVNAME"].abi);
var govBin = "0x" + govOutput.contracts["$GOVSOL:$GOVNAME"].bin;
var testTokenAbi = JSON.parse(testTokenOutput.contracts["$TESTTOKENSOL:$TESTTOKENNAME"].abi);
var testTokenBin = "0x" + testTokenOutput.contracts["$TESTTOKENSOL:$TESTTOKENNAME"].bin;

// console.log("DATA: ogTokenAbi=" + JSON.stringify(ogTokenAbi));
// console.log("DATA: ogTokenBin=" + JSON.stringify(ogTokenBin));
// console.log("DATA: govAbi=" + JSON.stringify(govAbi));
// console.log("DATA: govBin=" + JSON.stringify(govBin));
// console.log("DATA: testTokenAbi=" + JSON.stringify(testTokenAbi));
// console.log("DATA: testTokenBin=" + JSON.stringify(testTokenBin));


unlockAccounts("$PASSWORD");
// printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployGroup1_Message = "Deploy Group #1 - Contracts";

var ogTokenDecimals = 18;
var ogTokenSymbol = 'OGToken';
var ogTokenName = "Optino Governance Token (" + ogTokenDecimals + " dp)";
var ogTokenOwner = deployer;
var ogTokenInitialSupply = new BigNumber("0").shift(18);

var testTokenDecimals = 18;
var testTokenSymbol = 'TEST';
var testTokenName = "Test (" + testTokenDecimals + " dp)";
var testTokenOwner = deployer;
var testTokenInitialSupply = new BigNumber("321.123456789012345678").shift(18);

console.log("DATA: deployer=" + deployer);
console.log("DATA: defaultGasPrice=" + defaultGasPrice);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployGroup1_Message + " ----------");
var ogTokenContract = web3.eth.contract(ogTokenAbi);
// console.log("DATA: ogTokenContract=" + JSON.stringify(ogTokenContract));
var ogTokenTx = null;
var ogTokenAddress = null;
var ogToken = ogTokenContract.new(ogTokenSymbol, ogTokenName, ogTokenDecimals, ogTokenOwner, ogTokenInitialSupply, {from: deployer, data: ogTokenBin, gas: 4000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        ogTokenTx = contract.transactionHash;
      } else {
        ogTokenAddress = contract.address;
        addAccount(ogTokenAddress, "'" + ogToken.symbol.call() + "' '" + ogToken.name.call() + "'");
        addAddressSymbol(ogTokenAddress, "'" + ogToken.symbol.call() + "' '" + ogToken.name.call() + "'");
        addTokenContractAddressAndAbi(0, ogTokenAddress, ogTokenAbi);
        console.log("DATA: var ogTokenAddress=\"" + ogTokenAddress + "\";");
        console.log("DATA: var ogTokenAbi=" + JSON.stringify(ogTokenAbi) + ";");
        console.log("DATA: var ogToken=eth.contract(ogTokenAbi).at(ogTokenAddress);");
      }
    }
  }
);
var testTokenContract = web3.eth.contract(testTokenAbi);
// console.log("DATA: testTokenContract=" + JSON.stringify(testTokenContract));
var testTokenTx = null;
var testTokenAddress = null;
var testToken = testTokenContract.new(testTokenSymbol, testTokenName, testTokenDecimals, testTokenOwner, testTokenInitialSupply, {from: deployer, data: testTokenBin, gas: 4000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        testTokenTx = contract.transactionHash;
      } else {
        testTokenAddress = contract.address;
        addAccount(testTokenAddress, "'" + testToken.symbol.call() + "' '" + testToken.name.call() + "'");
        addAddressSymbol(testTokenAddress, "'" + testToken.symbol.call() + "' '" + testToken.name.call() + "'");
        addTokenContractAddressAndAbi(1, testTokenAddress, testTokenAbi);
        console.log("DATA: var testTokenAddress=\"" + testTokenAddress + "\";");
        console.log("DATA: var testTokenAbi=" + JSON.stringify(testTokenAbi) + ";");
        console.log("DATA: var testToken=eth.contract(testTokenAbi).at(testTokenAddress);");
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
var govContract = web3.eth.contract(govAbi);
// console.log("RESULT: govContract=" + JSON.stringify(govContract));
var govTx = null;
var govAddress = null;
var gov = govContract.new(ogTokenAddress, {from: deployer, data: govBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        govTx = contract.transactionHash;
      } else {
        govAddress = contract.address;
        addAccount(govAddress, "OptinoGov");
        addAddressSymbol(govAddress, "OptinoGov");
        addGovContractAddressAndAbi(govAddress, govAbi);
        console.log("DATA: var govAddress=\"" + govAddress + "\";");
        console.log("DATA: var govAbi=" + JSON.stringify(govAbi) + ";");
        console.log("DATA: var optinoTokenAbi=" + JSON.stringify(optinoTokenAbi) + ";");
        console.log("DATA: var gov=eth.contract(govAbi).at(govAddress);");
        // console.log("RESULT: govBin.length=" + govBin.length + ", /2=" + govBin.length / 2);
      }
    }
  }
);
var addDividendToken1_Tx = ogToken.addDividendToken(NULLACCOUNT, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var addDividendToken2_Tx = ogToken.addDividendToken(testTokenAddress, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(ogTokenTx, deployGroup1_Message + " - OGToken");
printTxData("ogTokenTx", ogTokenTx);
failIfTxStatusError(testTokenTx, deployGroup1_Message + " - TestToken");
printTxData("testTokenTx", testTokenTx);
failIfTxStatusError(govTx, deployGroup1_Message + " - Gov");
printTxData("govTx", govTx);
failIfTxStatusError(addDividendToken1_Tx, deployGroup1_Message + " - ogToken.addDividendToken(0x00)");
printTxData("addDividendToken1_Tx", addDividendToken1_Tx);
failIfTxStatusError(addDividendToken2_Tx, deployGroup1_Message + " - ogToken.addDividendToken(TEST)");
printTxData("addDividendToken2_Tx", addDividendToken2_Tx);
printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");
printTokenContractDetails(1);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var distributeAndApproveTokens_Message = "Distribute And Approve Tokens";
var ogTokensToDistribute = new BigNumber("1000").shift(18);
var ogTokensToApprove = new BigNumber("1000").shift(18);
var distApproveUsers = [user1, user2, user3, user4];
var distributeTokens_Txs = [];
var approveTokens_Txs = [];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + distributeAndApproveTokens_Message + " ----------");
for (var userIndex in distApproveUsers) {
  distributeTokens_Txs[userIndex] = ogToken.mint(distApproveUsers[userIndex], ogTokensToDistribute, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
  approveTokens_Txs[userIndex] = ogToken.approve(govAddress, ogTokensToApprove, {from: distApproveUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
}
while (txpool.status.pending > 0) {
}
var approveTokens_Txs[userIndex] = ogToken.approve(govAddress, ogTokensToApprove, {from: distApproveUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
printBalances();
for (var userIndex in distApproveUsers) {
  failIfTxStatusError(distributeTokens_Txs[userIndex], distributeAndApproveTokens_Message + " - ogToken.mint(" + getShortAddressName(distApproveUsers[userIndex]) + ", " + ogTokensToDistribute.shift(-18).toString() + ")");
  printTxData("distributeTokens_Txs[" + userIndex + "]", distributeTokens_Txs[userIndex]);
  failIfTxStatusError(approveTokens_Txs[userIndex], distributeAndApproveTokens_Message + " - ogToken.approve(" + getShortAddressName(govAddress) + ", " + ogTokensToApprove.shift(-18).toString() + ")");
  printTxData("approveTokens_Txs[" + userIndex + "]", approveTokens_Txs[userIndex]);
}
printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");
printTokenContractDetails(1);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var lockTokens_Message = "Lock Tokens";
var tokensToLock = new BigNumber("300").shift(18);
var lockDuration = 100; // 60 * 60 * 24 * 365; // 365 day
var lockUsers = [user1, user2, user3, user1]; // double for user1
var lockTokens_Txs = [];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + lockTokens_Message + " ----------");

for (var userIndex in lockUsers) {
  lockTokens_Txs[userIndex] = gov.lock(tokensToLock, lockDuration, {from: lockUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
}
var transferOwnership_Tx = ogToken.transferOwnershipImmediately(govAddress, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();

for (var userIndex in lockUsers) {
  failIfTxStatusError(lockTokens_Txs[userIndex], lockTokens_Message + " - " + getShortAddressName(lockUsers[userIndex]) + "-> gov.stake(" + tokensToLock.shift(-18).toString() + ", " + lockDuration + ")");
  printTxData("lockTokens_Txs[" + userIndex + "]", lockTokens_Txs[userIndex]);
}
failIfTxStatusError(transferOwnership_Tx, lockTokens_Message + " - ogToken.transferOwnershipImmediately("Gov")");
printTxData("transferOwnership_Tx", transferOwnership_Tx);

printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");
printTokenContractDetails(1);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var stakeTokens_Message = "Stake Tokens";
var tokensToStakeForTokens = new BigNumber("10").shift(18);
var tokensToStakeForFeeds = new BigNumber("15").shift(18);
var stakeUsers = [user1, user2, user3];
var stakeTokensForTokens_Txs = [];
var stakeTokensForFeed_Txs = [];
var FEEDADDRESS = "0xfeedfeedfeedfeedfeedfeedfeedfeedfeedfeed";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + stakeTokens_Message + " ----------");

for (var userIndex in stakeUsers) {
  stakeTokensForTokens_Txs[userIndex] = gov.addStakeForToken(tokensToStakeForTokens, testTokenAddress, "Testing", {from: stakeUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
  stakeTokensForFeed_Txs[userIndex] = gov.addStakeForFeed(tokensToStakeForFeeds, FEEDADDRESS, 1, 9, "Feed:ETH/USD", {from: stakeUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
}
while (txpool.status.pending > 0) {
}
printBalances();

for (var userIndex in stakeUsers) {
  failIfTxStatusError(stakeTokensForTokens_Txs[userIndex], stakeTokens_Message + " - " + getShortAddressName(stakeUsers[userIndex]) + "-> gov.addStakeForToken(" + tokensToStakeForTokens.shift(-18).toString() + ", " + getShortAddressName(testTokenAddress) + ")");
  printTxData("stakeTokensForTokens_Txs[" + userIndex + "]", stakeTokensForTokens_Txs[userIndex]);
  failIfTxStatusError(stakeTokensForFeed_Txs[userIndex], stakeTokens_Message + " - " + getShortAddressName(stakeUsers[userIndex]) + "-> gov.addStakeForFeed(" + tokensToStakeForFeeds.shift(-18).toString() + ", " + getShortAddressName(FEEDADDRESS) + ")");
  printTxData("stakeTokensForFeed_Txs[" + userIndex + "]", stakeTokensForFeed_Txs[userIndex]);
}

printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");
printTokenContractDetails(1);
console.log("RESULT: ");

// -----------------------------------------------------------------------------
var submitProposal_Message = "Submit Proposal";
var mintTokens = new BigNumber("888.888").shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + submitProposal_Message + " ----------");
console.log("RESULT: DEBUG 1");
// var dataString = "0x" + ogToken.mint.getData(user3, mintTokens).substring(10);
// dataString = web3.fromAscii("Testing 123");
// console.log("RESULT: DEBUG 2 dataString=" + dataString);
// var data = web3.toUtf8(dataString);
// console.log("RESULT: DEBUG 3 data=" + JSON.stringify(data));
// console.log("RESULT: ogToken.mint.getData(user3, mintTokens)=" + JSON.stringify(dataString));
// var dataString1 = gov.propose.getData([ogTokenAddress], [0], ["mint(address,uint256)"], [], "Proposal 1");
// var dataString1 = gov.propose.getData([], [], [], ["0x1234"], "test");
console.log("RESULT: user3=" + user3);
var user3without0x = user3.replace('0x', '');
console.log("RESULT: user3without0x=" + user3without0x);
// var bytes = '0x' + web3.utils.padLeft(user3without0x, 64);
var bytes = '0x000000000000000000000000' + user3without0x + "00000000000000000000000000000000000000000000000000000000000000c0";
console.log("RESULT: bytes=" + bytes + " = " +  web3.toAscii(bytes));
// var testBytes = web3.fromAscii("test");
// console.log("RESULT: testBytes=" + JSON.stringify(testBytes));
// var text1 = '0x' + web3.utils.padLeft(testBytes.replace('0x', ''), 64);
// var dataString1 = gov.propose.getData([], [], [text1], [bytes], "test");
// dataString1 = "0xda95691a00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002123400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000047465737400000000000000000000000000000000000000000000000000000000";
// console.log("RESULT: gov.propose.getData(...)=" + JSON.stringify(dataString1));
// var submitProposal_Tx = eth.sendTransaction({to: govAddress, value: 0, input: dataString1, from: user3, gas: 2000000, gasPrice: defaultGasPrice});
// var submitProposal_Tx = gov.propose([ogTokenAddress], [0], ["mint(address,uint256)"], ["0x1234"], "Proposal 1", {from: user3, gas: 2000000, gasPrice: defaultGasPrice});
// var submitProposal_Tx = gov.propose(ogTokenAddress, 0, ["mint(address,uint256)"], web3.fromAscii(web3.toAscii(bytes)), "Proposal 1", {from: user3, gas: 2000000, gasPrice: defaultGasPrice});
var submitProposal_Tx = gov.propose("Proposal 1", ogTokenAddress, 0, "mint(address,uint256)", bytes, {from: user3, gas: 2000000, gasPrice: defaultGasPrice});
// function propose(string memory description, address target, uint value, string memory signature, bytes memory data) public returns(uint)
while (txpool.status.pending > 0) {
}
var executeProposal_Tx = gov.execute(1, {from: user3, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(submitProposal_Tx, submitProposal_Message + " - user3-> gov.propose(Proposal1)");
printTxData("submitProposal_Tx", submitProposal_Tx);
failIfTxStatusError(executeProposal_Tx, submitProposal_Message + " - user3-> gov.execute(1)");
printTxData("executeProposal_Tx", executeProposal_Tx);
printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");
printTokenContractDetails(1);
console.log("RESULT: ");



if (false) {
  // -----------------------------------------------------------------------------
  var burnStakes_Message = "Burn Stakes";
  var percentToBurnForTokens = new BigNumber("25");
  var percentToBurnForFeeds = new BigNumber("75");
  var burnUsers = [user1, user2, user3];
  // -----------------------------------------------------------------------------
  console.log("RESULT: ---------- " + burnStakes_Message + " ----------");
  var stakingKeyForToken = gov.stakeInfoIndex.call(0);
  var stakingKeyForFeed = gov.stakeInfoIndex.call(1);
  var burnForTokens_Tx = gov.burnStake(burnUsers, stakingKeyForToken, percentToBurnForTokens, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
  var burnForFeed_Tx = gov.burnStake(burnUsers, stakingKeyForFeed, percentToBurnForFeeds, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  printBalances();
  failIfTxStatusError(burnForTokens_Tx, burnStakes_Message + " - deployer-> gov.burnStake(" + JSON.stringify(burnUsers) + ", " + stakingKeyForToken + ", " + percentToBurnForTokens.toString() + "%)");
  printTxData("burnForTokens_Tx", burnForTokens_Tx);
  failIfTxStatusError(burnForFeed_Tx, burnStakes_Message + " - deployer-> gov.burnStake(" + JSON.stringify(burnUsers) + ", " + stakingKeyForFeed + ", " + percentToBurnForFeeds.toString() + "%)");
  printTxData("burnForFeed_Tx", burnForFeed_Tx);
  printGovContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
}


if (false) {
  // -----------------------------------------------------------------------------
  var collectLockRewards_Message = "Collect Lock Rewards";
  var collectLockRewardUsers = [user3];
  var collectLockReward_Txs = [];
  // -----------------------------------------------------------------------------
  console.log("RESULT: ---------- " + collectLockRewards_Message + " ----------");

  for (var userIndex in collectLockRewardUsers) {
    collectLockReward_Txs[userIndex] = gov.collectLockReward({from: collectLockRewardUsers[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
  }
  while (txpool.status.pending > 0) {
  }
  printBalances();

  for (var userIndex in collectLockRewardUsers) {
    failIfTxStatusError(collectLockReward_Txs[userIndex], collectLockRewards_Message + " - " + getShortAddressName(collectLockRewardUsers[userIndex]) + "-> gov.collect()");
    printTxData("collectLockReward_Txs[" + userIndex + "]", collectLockReward_Txs[userIndex]);
  }

  printGovContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
}


exit;

if (true) {
  // -----------------------------------------------------------------------------
  var closeGroup1_Message = "Close Optino & Cover";
  // var closeAmount = optino.balanceOf.call(seller1);
  var closeAmount = optino.balanceOf.call(seller1).mul(5).div(10);
  // var optino = web3.eth.contract(optinoTokenAbi).at(optinos[0]);
  // -----------------------------------------------------------------------------
  console.log("RESULT: ---------- " + closeGroup1_Message + " ----------");
  var closeGroup1_1Tx = optino.close(closeAmount, {from: seller1, gas: 2000000, gasPrice: defaultGasPrice});
  // var closeGroup1_1Tx = optino.closeFor(seller1, closeAmount, {from: seller1, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  printBalances();
  failIfTxStatusError(closeGroup1_1Tx, closeGroup1_Message + " - optino.close(" + closeAmount.shift(-OPTINODECIMALS).toString() + ")");
  printTxData("closeGroup1_1Tx", closeGroup1_1Tx);
  console.log("RESULT: ");
  printPriceFeedContractDetails();
  console.log("RESULT: ");
  printPriceFeedAdaptorContractDetails();
  console.log("RESULT: ");
  printOptinoFactoryContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
  printTokenContractDetails(2);
  console.log("RESULT: ");
  printTokenContractDetails(3);
  console.log("RESULT: ");
}


if (false) {
  // -----------------------------------------------------------------------------
  var settleGroup1_Message = "Settle Optino & Cover";
  // var rate = callPut == "0" ? new BigNumber("250").shift(rateDecimals0) : new BigNumber("166.666666666666666667").shift(rateDecimals0);
  // var makerdaoFeed0Value = new BigNumber("190.901").shift(rateDecimals0); // ETH/USD 190.901
  // var makerdaoFeed0Value = new BigNumber("1.695").shift(rateDecimals0); // MKR/ETH 1.695
  // console.log("DATA: makerdaoFeed0Value ETH/USD=" + makerdaoFeed0Value.shift(-rateDecimals0).toString());
  // console.log("DATA: makerdaoFeed0Value MKR/ETH=" + makerdaoFeed0Value.shift(-rateDecimals0).toString());
// -----------------------------------------------------------------------------
  console.log("RESULT: ---------- " + settleGroup1_Message + " ----------");
  // waitUntil("optino.expiry()", optino.expiry.call(), 0);
  waitUntil("optino.expiry()", expiry, 0);
  // var settleGroup1_1Tx = makerdaoFeed0.setValue(rate, true, {from: deployer, gas: 6000000, gasPrice: defaultGasPrice});
  // while (txpool.status.pending > 0) {
  // }
  var settleGroup1_2Tx = optino.settle({from: seller1, gas: 2000000, gasPrice: defaultGasPrice});
  // var settleGroup1_2Tx = optino.settleFor(seller1, {from: buyer1, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  printBalances();
  // failIfTxStatusError(settleGroup1_1Tx, settleGroup1_Message + " - makerdaoFeed0.setValue(" + rate.shift(-rateDecimals0).toString() + ", true)");
  // printTxData("settleGroup1_1Tx", settleGroup1_1Tx);
  failIfTxStatusError(settleGroup1_2Tx, settleGroup1_Message + " - seller1 -> optino.settle()");
  printTxData("settleGroup1_2Tx", settleGroup1_2Tx);
  console.log("RESULT: ");
  printPriceFeedContractDetails();
  console.log("RESULT: ");
  printPriceFeedAdaptorContractDetails();
  console.log("RESULT: ");
  printOptinoFactoryContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
  printTokenContractDetails(2);
  console.log("RESULT: ");
  printTokenContractDetails(3);
  console.log("RESULT: ");
}


if (true) {
  // -----------------------------------------------------------------------------
  var transferThenSettleGroup1_Message = "Transfer, then settle Optino & Cover";
  var rate = new BigNumber("250").shift(rateDecimals0);
  var transferAmount = optino.balanceOf.call(seller1).mul(4).div(8);
  console.log("RESULT: transferAmount=" + transferAmount.shift(-OPTINODECIMALS).toString());
  // var optino = web3.eth.contract(optinoTokenAbi).at(optinos[0]);
  // -----------------------------------------------------------------------------
  console.log("RESULT: ---------- " + transferThenSettleGroup1_Message + " ----------");
  waitUntil("optino.expiry()", expiry, 0);
  // waitUntil("optino.expiry()", optino.expiry.call(), 0);

  var transferThenSettleGroup1_1Tx = optino.transfer(buyer1, transferAmount.toString(), {from: seller1, gas: 1000000, gasPrice: defaultGasPrice});
  var transferThenSettleGroup1_2Tx = cover.transfer(buyer2, transferAmount.toString(), {from: seller1, gas: 1000000, gasPrice: defaultGasPrice});
  // var transferThenSettleGroup1_3Tx = makerdaoFeed0.setValue(rate, true, {from: deployer, gas: 6000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  var transferThenSettleGroup1_4Tx = optino.settle({from: seller1, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  printBalances();
  failIfTxStatusError(transferThenSettleGroup1_1Tx, transferThenSettleGroup1_Message + " - seller1 -> optino.transfer(buyer1, " + transferAmount.shift(-OPTINODECIMALS).toString() + ")");
  printTxData("transferThenSettleGroup1_1Tx", transferThenSettleGroup1_1Tx);
  failIfTxStatusError(transferThenSettleGroup1_2Tx, transferThenSettleGroup1_Message + " - seller1 -> cover.transfer(buyer2, " + transferAmount.shift(-OPTINODECIMALS).toString() + ")");
  printTxData("transferThenSettleGroup1_2Tx", transferThenSettleGroup1_2Tx);
  // failIfTxStatusError(transferThenSettleGroup1_3Tx, transferThenSettleGroup1_Message + " - deployer -> makerdaoFeed0.setValue(" + rate.shift(-rateDecimals0).toString() + ", true)");
  // printTxData("transferThenSettleGroup1_3Tx", transferThenSettleGroup1_3Tx);
  failIfTxStatusError(transferThenSettleGroup1_4Tx, transferThenSettleGroup1_Message + " - seller1 -> optino.settle()");
  printTxData("transferThenSettleGroup1_4Tx", transferThenSettleGroup1_4Tx);
  console.log("RESULT: ");
  printPriceFeedContractDetails();
  console.log("RESULT: ");
  printPriceFeedAdaptorContractDetails();
  console.log("RESULT: ");
  printOptinoFactoryContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
  printTokenContractDetails(2);
  console.log("RESULT: ");
  printTokenContractDetails(3);
  console.log("RESULT: ");

  var transferThenSettleGroup1_5Tx = optino.settle({from: buyer1, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  var transferThenSettleGroup1_6Tx = optino.settle({from: buyer2, gas: 2000000, gasPrice: defaultGasPrice});
  while (txpool.status.pending > 0) {
  }
  printBalances();
  failIfTxStatusError(transferThenSettleGroup1_5Tx, transferThenSettleGroup1_Message + " - buyer1 -> optino.settle()");
  printTxData("transferThenSettleGroup1_5Tx", transferThenSettleGroup1_5Tx);
  failIfTxStatusError(transferThenSettleGroup1_6Tx, transferThenSettleGroup1_Message + " - buyer2 -> optino.settle()");
  printTxData("transferThenSettleGroup1_6Tx", transferThenSettleGroup1_6Tx);
  console.log("RESULT: ");
  printOptinoFactoryContractDetails();
  console.log("RESULT: ");
  printTokenContractDetails(0);
  console.log("RESULT: ");
  printTokenContractDetails(1);
  console.log("RESULT: ");
  printTokenContractDetails(2);
  console.log("RESULT: ");
  printTokenContractDetails(3);
  console.log("RESULT: ");
}

console.log("RESULT: --- Main contracts gas usage ---");
printTxData("optinoTokenTx", optinoTokenTx);
printTxData("optinoFactoryTx", optinoFactoryTx);
printTxData("mintOptinoGroup1_1Tx", mintOptinoGroup1_1Tx);
console.log("RESULT: optinoFactoryBin.length=" + optinoFactoryBin.length + ", /2=" + optinoFactoryBin.length / 2);
console.log("RESULT: optinoTokenBin.length=" + optinoTokenBin.length + ", /2=" + optinoTokenBin.length / 2);


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
# egrep -e "tokenTx.*gasUsed|govTx.*gasUsed" $TEST1RESULTS
