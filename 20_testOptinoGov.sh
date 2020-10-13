#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TESTINPUT=test/TestOptinoGov.test.js
TESTOUTPUT=results/TestOptinoGov.txt

echo "\$ truffle test $TESTINPUT > $TESTOUTPUT" | tee $TESTOUTPUT

truffle test $TESTINPUT | tee -a $TESTOUTPUT
