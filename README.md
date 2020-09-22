# Gubbernance
Gubbernance

```
# https://github.com/trufflesuite/truffle
npm install -g truffle
truffle init
truffle compile
truffle migrate
npm install web3@1.2.1

npm install truffle-flattener -g
truffle-flattener contracts/OGToken.sol > flattened/OGToken_flattened.sol
npm install bignumber.js

truffle console
> let instance = await TestToken.deployed()
> instance

> let accounts = await web3.eth.getAccounts()
> accounts

let balanceOf = await instance.balanceOf(accounts[0])

```
