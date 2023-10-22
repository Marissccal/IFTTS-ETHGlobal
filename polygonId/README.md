# Node Register with Zero-Knowledge Proof Validation

NodeRegister.sol integrates zk-SNARK proof validation to register a new Node in the protocol. Upon successful validation, the new Node is registered with its wallet address.

## Polygon ID Wallet setup

1. Download the Polygon ID mobile app on the [Google Play](https://play.google.com/store/apps/details?id=com.polygonid.wallet)

2. Open the app and set a pin for security

3. Issue yourself a Credential of type `Kyc Age Credential Merklized` from the [Polygon ID Issuer Sandbox](https://issuer-v2.polygonid.me/)

## Instructions to compile and deploy the smart contract

1. Create a .env file in the root of this repo

2. Install dependencies
   `npm i`

3. Compile smart contracts
   `npx hardhat compile`

4. Deploy smart contracts
   npx hardhat run --network mumbai scripts/deploynodeKYC.js

5. Update the `VerifierAddress` variable in scripts/set-request.js with your deployed contract address

6. Run set-request to send the zk request to the smart contract

   npx hardhat run --network mumbai scripts/set-request.js

## execute NodeRegister since FE

1. Design a proof request (see my example in qrValueProofRequestExample.json)

   - Update the `contract_address` field to your deployed contract address

2. Create a frontend that renders the proof request in json format into a QR code. [Codesandbox example](https://codesandbox.io/s/zisu81?file=/index.js)

## Scroll example, need to customize de polygon Id wallet to make a proof to another chain

npx hardhat run --network scroll scripts/deploynodeKYC.js exampleScrollNode = https://sepolia.scrollscan.dev/address/0xd6726a3332711ad54c3649866e07218b40e34adc

in this case using hashRoleControl contract https://sepolia.scrollscan.dev/address/0xb832c006e92b345fe0531ad2a039a71825e3119c

originalMessage = 0x9fbc8af38d936a0b1403cc71c6e1308a2b11fa3a8f1ddce97e71270b38d99344
expectedHash = 0x513722af688fb5b9ed0d42913725d1b00124230ed4890173ffc65ddfd585628d

Video https://www.youtube.com/watch?v=OAl1slJ1o7s

X @leanlp
