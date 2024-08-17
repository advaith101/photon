# Photon: An Optimized Limit Order Book (LOB) Decentralized Exchange on EVM.

## Setup
.env file with the following variables:  
MAINNET_RPC_URL - an infura or other RPC provider to fork mainnet.


## Install Dependencies

```npm install``` or ```yarn install```

## Deploy contracts (on local node that is fork of mainnet)

Run local node: ```npx hardhat node --network hardhat```  
Deploy: ```npx hardhat run scripts/deploy.js --network localhost```

## Test

```npx hardhat test```

