import Web3 from "web3";

require('dotenv').config();

async function signMessage() {
       const web3 = new Web3(process.env.WEB3_PROVIDER_URL as string);

       const privateKey = process.env.ADDRESS_PK as string;

       const messageHash = "0x592fa743889fc7f92ac2a37bb1f5ba1daf2a5c84741ca0e0061d243a2e6707ba";

       const signature = await web3.eth.accounts.sign(messageHash as string, privateKey);
       const signatureFull = "0x487646cdc119c536137467b592b52485c22fd41488f12b5e7f0a70471ae95f7e1e90d5e9687cda52ddb632ec397a3686c2d5d85fad6ea048fc6bb72f5354adcf1c";

       const r = signatureFull.slice(0, 66);
       const s = '0x' + signatureFull.slice(66, 130);
       const v = parseInt(signatureFull.slice(130, 132), 16);

       console.log("r:", r);
       console.log("s:", s);
       console.log("v:", v);


       console.log("Signature:", signature.signature);

       const signer = web3.eth.accounts.recover(messageHash, signature.signature);
       console.log("Signer:", signer);

       return signature.signature;


}

signMessage();