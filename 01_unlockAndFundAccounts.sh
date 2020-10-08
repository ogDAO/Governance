#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Unlock a few accounts and transfer some funds from eth.accounts[0] 
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
GETHATTACHPOINT=rpc:http://localhost:8545

geth --verbosity 3 attach $GETHATTACHPOINT << EOF

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length && i < 5; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
    if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
      personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
    }
  }
  while (txpool.status.pending > 0) {
  }
  baseBlock = eth.blockNumber;
}

unlockAccounts("");

EOF
