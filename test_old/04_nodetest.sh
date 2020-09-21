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


DIFFS1=`diff -r -x '*.js' -x '*.json' -x '*.txt' -x 'testchain' -x '*.md' -x '*.sh' -x 'settings' -x 'node_modules' -x 'modifiedContracts' $SOURCEDIR .`
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

node << EOF

const { ethers } = require("ethers");
console.log("RESULT: Loaded ethers");

const provider = new ethers.providers.IpcProvider("./testchain/geth.ipc");
// const provider = new ethers.providers.JsonRpcProvider();
// const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
// const network = {
//     name: "dev",
//     chainId: 1337
// };
// const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545", network);
console.log("RESULT: Loaded provider");

const signer = provider.getSigner();
console.log("RESULT: Loaded signer");

loadScript("$OGTOKENJS");
loadScript("$GOVJS");
loadScript("$TESTTOKENJS");


async function test() {
  const blockNumber = await provider.getBlockNumber();
  console.log("blockNumber: " + blockNumber);
}

test();

EOF
