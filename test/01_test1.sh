#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019. The MIT Licence.
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
rsync -rp $SOURCEDIR/* . --exclude=Multisig.sol --exclude=test/ # */
# rsync -rp $SOURCEDIR/* . --exclude=Multisig.sol # */
# Copy modified contracts if any files exist
# find ./modifiedContracts -type f -name \* -exec cp {} . \;

# --- Modify parameters ---
# `perl -pi -e "s/openzeppelin-solidity/\.\.\/\.\.\/openzeppelin-solidity/" token/dataStorage/*.sol`

# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$MINTABLETOKENSOL --outputsol=$TESTTOKENFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$MAKERDAOFEEDSOL --outputsol=$MAKERDAOFEEDFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$FEEDADAPTORSOL --outputsol=$FEEDADAPTORFLATTENED --verbose | tee -a $TEST1OUTPUT
# ../scripts/solidityFlattener.pl --contractsdir=$SOURCEDIR --mainsol=$OPTINOFACTORYSOL --outputsol=$OPTINOFACTORYFLATTENED --verbose | tee -a $TEST1OUTPUT


# DIFFS1=`diff -r -x '*.js' -x '*.json' -x '*.txt' -x 'testchain' -x '*.md' -x '*.sh' -x 'settings' -x 'modifiedContracts' $SOURCEDIR .`
# echo "--- Differences $SOURCEDIR/*.sol *.sol ---" | tee -a $TEST1OUTPUT
# echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.7.1 --version | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc_0.7.1 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $TESTTOKENSOL`;" > $TESTTOKENJS
echo "var govOutput=`solc_0.7.1 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $GOVSOL`;" > $GOVJS

if [ "$MODE" = "compile" ]; then
  echo "Compiling only"
  exit 1;
fi


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TESTTOKENJS");
loadScript("$GOVJS");
loadScript("lookups.js");
loadScript("functions.js");

var tokenAbi = JSON.parse(tokenOutput.contracts["$TESTTOKENSOL:$TESTTOKENNAME"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$TESTTOKENSOL:$TESTTOKENNAME"].bin;
var govAbi = JSON.parse(govOutput.contracts["$GOVSOL:$GOVNAME"].abi);
var govBin = "0x" + govOutput.contracts["$GOVSOL:$GOVNAME"].bin;

// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));
// console.log("DATA: govAbi=" + JSON.stringify(govAbi));
// console.log("DATA: govBin=" + JSON.stringify(govBin));

unlockAccounts("$PASSWORD");
// printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployGroup1_Message = "Deploy Group #1 - Contracts";

var tokenDecimals = 18;
var tokenSymbol = 'TEST';
var tokenName = "Test (" + tokenDecimals + " dp)";
var tokenOwner = deployer;
var initialSupply = new BigNumber("0").shift(18);

console.log("DATA: deployer=" + deployer);
console.log("DATA: defaultGasPrice=" + defaultGasPrice);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployGroup1_Message + " ----------");
var tokenContract = web3.eth.contract(tokenAbi);
// console.log("DATA: tokenContract=" + JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var token = tokenContract.new(tokenSymbol, tokenName, tokenDecimals, tokenOwner, initialSupply, {from: deployer, data: tokenBin, gas: 4000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "'" + token.symbol.call() + "' '" + token.name.call() + "'");
        addAddressSymbol(tokenAddress, "'" + token.symbol.call() + "' '" + token.name.call() + "'");
        addTokenContractAddressAndAbi(0, tokenAddress, tokenAbi);
        console.log("DATA: var tokenAddress=\"" + tokenAddress + "\";");
        console.log("DATA: var tokenAbi=" + JSON.stringify(tokenAbi) + ";");
        console.log("DATA: var token=eth.contract(tokenAbi).at(tokenAddress);");
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
var gov = govContract.new(tokenAddress, {from: deployer, data: govBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        govTx = contract.transactionHash;
      } else {
        govAddress = contract.address;
        addAccount(govAddress, "Gov");
        addAddressSymbol(govAddress, "Gov");
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
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(govTx, deployGroup1_Message + " - Gov");
printTxData("govTx", govTx);
failIfTxStatusError(tokenTx, deployGroup1_Message + " - Token");
printTxData("tokenTx", tokenTx);
printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var distributeAndApproveTokens_Message = "Distribute And Approve Tokens";
var tokensToDistribute = new BigNumber("1000").shift(18);
var tokensToApprove = new BigNumber("100").shift(18);
// var users = [user1, user2, user3, user4];
var users = [user1, user2];
var distributeTokens_Txs = [];
var approveTokens_Txs = [];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + distributeAndApproveTokens_Message + " ----------");

for (var userIndex in users) {
  distributeTokens_Txs[userIndex] = token.mint(users[userIndex], tokensToDistribute, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
  approveTokens_Txs[userIndex] = token.approve(govAddress, tokensToApprove, {from: users[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
}
while (txpool.status.pending > 0) {
}
printBalances();

for (var userIndex in users) {
  failIfTxStatusError(distributeTokens_Txs[userIndex], distributeAndApproveTokens_Message + " - token.mint(" + users[userIndex] + ", " + tokensToDistribute.shift(-18).toString() + ")");
  printTxData("distributeTokens_Txs[" + userIndex + "]", distributeTokens_Txs[userIndex]);
  failIfTxStatusError(approveTokens_Txs[userIndex], distributeAndApproveTokens_Message + " - token.approve(" + govAddress + ", " + tokensToApprove.shift(-18).toString() + ")");
  printTxData("approveTokens_Txs[" + userIndex + "]", approveTokens_Txs[userIndex]);
}

printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var stakeTokens_Message = "Stake Tokens";
var tokensToStake = new BigNumber("10").shift(18);
var stakeDuration = 60 * 60 * 24 * 365; // 365 day
var users = [user1, user2, user1];
var stakeTokens_Txs = [];
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + stakeTokens_Message + " ----------");

for (var userIndex in users) {
  stakeTokens_Txs[userIndex] = gov.stake(tokensToStake, stakeDuration, {from: users[userIndex], gas: 2000000, gasPrice: defaultGasPrice});
}
while (txpool.status.pending > 0) {
}
printBalances();

for (var userIndex in users) {
  failIfTxStatusError(stakeTokens_Txs[userIndex], stakeTokens_Message + " - " + users[userIndex] + "-> gov.stake(" + tokensToStake.shift(-18).toString() + ", " + stakeDuration + ")");
  printTxData("stakeTokens_Txs[" + userIndex + "]", stakeTokens_Txs[userIndex]);
}

printGovContractDetails();
console.log("RESULT: ");
printTokenContractDetails(0);
console.log("RESULT: ");


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
egrep -e "tokenTx.*gasUsed|govTx.*gasUsed" $TEST1RESULTS
