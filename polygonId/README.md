NodeRegister.sol tiene integrado la validacion de zk proof, en caso de ser valida, registra el nuevo Nodo con su wallet address. en scrool, debemos de usar hashrol SC
example 

originalMessage= 0x9fbc8af38d936a0b1403cc71c6e1308a2b11fa3a8f1ddce97e71270b38d99344
(expectedHash)hash role= 0x513722af688fb5b9ed0d42913725d1b00124230ed4890173ffc65ddfd585628d




## Polygon ID Wallet setup

1. Download the Polygon ID mobile app on the [Google Play](https://play.google.com/store/apps/details?id=com.polygonid.wallet) or [Apple app store](https://apps.apple.com/us/app/polygon-id/id1629870183)

2. Open the app and set a pin for security

3. Issue yourself a Credential of type `Kyc Age Credential Merklized` from the [Polygon ID Issuer Sandbox](https://issuer-v2.polygonid.me/)

## Instructions to compile and deploy the smart contract

1. Create a .env file in the root of this repo. Copy in .env.sample to add keys
    `touch .env`

2. Install dependencies
    `npm i`

3. Compile smart contracts
    `npx hardhat compile`

4. Deploy smart contracts
    npx hardhat run --network mumbai scripts/deploynodeKYC.js

    npx hardhat run --network scroll scripts/deploynodeKYC.js   exampleScrollNode = https://sepolia.scrollscan.dev/address/0xd6726a3332711ad54c3649866e07218b40e34adc
    
    in this case using hashRoleControl contract                                     https://sepolia.scrollscan.dev/address/0xb832c006e92b345fe0531ad2a039a71825e3119c


5. Update the `VerifierAddress` variable in scripts/set-request.js with your deployed contract address

6. Run set-request to send the zk request to the smart contract
    `npx hardhat run --network mumbai scripts/set-request.js`
   
## execute NodeRegister since FE

1. Design a proof request (see my example in qrValueProofRequestExample.json)
    - Update the `contract_address` field to your deployed contract address

2. Create a frontend that renders the proof request in json format into a QR code. [Codesandbox example](https://codesandbox.io/s/zisu81?file=/index.js) 



https://mumbai.polygonscan.com/txs?a=0xb3e1275be2649e8cf8e4643da197d6f7b309626a



