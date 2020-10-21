#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TESTINPUT=test/TestOGDToken.js
TESTOUTPUT=results/TestOGDToken.txt

echo "\$ time npx buidler test $TESTINPUT > $TESTOUTPUT" | tee $TESTOUTPUT

time npx buidler test $TESTINPUT | tee -a $TESTOUTPUT

# Strip out unnamed event parameters
# sed -i '' 's/(0:.*length__: [0-9]*, /(/g' $TESTOUTPUT
