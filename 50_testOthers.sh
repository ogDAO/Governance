#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TEST1INPUT=test/TestInterestUtils.js
TEST2OUTPUT=results/TestInterestUtils.txt

# Clear scollback buffer and screen
printf "\033[2J\033[3J\033[1;1H"

echo "\$ npx hardhat test $TEST1INPUT > $TEST2OUTPUT" | tee $TEST2OUTPUT

npx hardhat test $TEST1INPUT | tee -a $TEST2OUTPUT

echo "        --- 1y compounding period ---"
grep "period: 1y" results/TestInterestUtils.txt
echo ""
echo "        --- 6m compounding period ---"
grep "period: 6m" results/TestInterestUtils.txt
echo ""
echo "        --- 3m compounding period ---"
grep "period: 3m" results/TestInterestUtils.txt
echo ""
echo "        --- 1m compounding period ---"
grep "period: 1m" results/TestInterestUtils.txt
echo ""
echo "        --- 7d compounding period ---"
grep "period: 7d" results/TestInterestUtils.txt
echo ""
echo "        --- 1d compounding period ---"
grep "period: 1d" results/TestInterestUtils.txt


TEST2INPUT=test/TestSimpleCurve.js
TEST2OUTPUT=results/TestSimpleCurve.txt

echo "\$ npx hardhat test $TEST2INPUT > $TEST2OUTPUT" | tee $TEST2OUTPUT

npx hardhat test $TEST2INPUT | tee -a $TEST2OUTPUT
