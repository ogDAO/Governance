#!/bin/sh
# ----------------------------------------------------------------------------------------------
# Run `geth --dev` with additional parameters
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------

rm -f ./testchain/geth/chaindata/ancient/*
rmdir ./testchain/geth/chaindata/ancient
rm -f ./testchain/geth/chaindata/*

geth --allow-insecure-unlock --dev --dev.period 1 --datadir ./testchain --rpc --rpccorsdomain '*' --rpcport 8545 --rpcapi "admin,debug,eth,ethash,miner,net,personal,rpc,txpool,web3" --port 32323 --maxpeers 0 --targetgaslimit 994712388 console
