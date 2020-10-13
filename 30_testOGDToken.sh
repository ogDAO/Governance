#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TESTINPUT=test/TestOGDToken.test.js
TESTOUTPUT=results/TestOGDToken.txt

echo "\$ truffle test $TESTINPUT > $TESTOUTPUT" | tee $TESTOUTPUT

truffle test $TESTINPUT | tee -a $TESTOUTPUT

# Strip out unnamed event parameters
sed -i '' 's/(0:.*length__: [0-9]*, /(/g' $TESTOUTPUT
