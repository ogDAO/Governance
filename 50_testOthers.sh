#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TESTINPUT=test/TestInterestUtils.js
TESTOUTPUT=results/TestInterestUtils.txt

echo "\$ npx hardhat test $TESTINPUT > $TESTOUTPUT" | tee $TESTOUTPUT

npx hardhat test $TESTINPUT | tee -a $TESTOUTPUT

echo "        --- 1y period ---"
grep "period: 1y" results/TestInterestUtils.txt
echo ""
echo "        --- 6m period ---"
grep "period: 6m" results/TestInterestUtils.txt
echo ""
echo "        --- 3m period ---"
grep "period: 3m" results/TestInterestUtils.txt
echo ""
echo "        --- 1m period ---"
grep "period: 1m" results/TestInterestUtils.txt
echo ""
echo "        --- 1d period ---"
grep "period: 1d" results/TestInterestUtils.txt
