#!/bin/sh

rm -rf flattened/
mkdir flattened/
truffle-flattener contracts/OGToken.sol > flattened/OGToken_flattened.sol
truffle-flattener contracts/OGDToken.sol > flattened/OGDToken_flattened.sol
truffle-flattener contracts/OptinoGov.sol > flattened/OptinoGov_flattened.sol
truffle-flattener contracts/StakingFactory.sol > flattened/StakingFactory_flattened.sol
truffle-flattener contracts/POAPOGTokenStation.sol > flattened/POAPOGTokenStation_flattened.sol
truffle-flattener contracts/TestToken.sol > flattened/TestToken_flattened.sol
