#!/bin/sh

rm -rf flattened/
mkdir flattened/
truffle-flattener contracts/OGToken.sol > flattened/OGToken.sol
truffle-flattener contracts/OptinoGov.sol > flattened/OptinoGov.sol
truffle-flattener contracts/POAPOGTokenStation.sol > flattened/POAPOGTokenStation.sol
truffle-flattener contracts/TestToken.sol > flattened/TestToken.sol
