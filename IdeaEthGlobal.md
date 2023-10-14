Decentralized IFTTS using MPC

TSS


Definitions:

Account with N of M signers. 

Each account has installed a series of IFTTT rules.


IFTTT rule: <target address, payload_header bytes>

These rules are pure functions that receive a fixed set of parameters + a list of *facts*.

This produces a bytes output if doesn't revert (if the condition is not met).


# Fact

A fact is something that happened in a blockchain (not necesary the home-blockchain of the protocol) where it can be proven that happened.

Kind of facts:

1. Events: <event signature>, tx hash, log_index, block hash, block timestamp, min block confirmations, chain id>

2. Calls: <target>, <call>, <result>, <blocknumber>, <min block confirmations>, <chain id>

3. Balance

4. Block: <number>, <timestamp>, <hash>


# Account creation

A creator pays the account creation price and indicates initialization parameters:

1. N/M signers (number of required signers N, number of total signers M).

2. Initial set of facts 

3. Owner that can destroy the account, change the facts, etc. Can be address(0) or revoked if you want to make it fully decentralized.

4. Creation fee.

5. Renewal deadline, max number of signatures, renewal fee.


Then signers submit the key share. Only a signer whose address mod M is i can provide share i. 

When all the signers submit the key share, the account is created, and the address emitted as event.


# Responsabilities of the signers

They have to sign signature requests if they are valid. 

Signature Request: 

1. List of facts.
2. IFTTT rule 
3. Account 
4. Bytes to sign 

Checks they have to do:

1. Each of the facts is real.
2. The IFTTT rule is active for the account.
3. Calling the IFTTT.target(payload_header | facts) == Bytes to sign 

If all this happens, the signer produces signature 


# Offenses

1. Signing something that wasn't produced by an IFTTT rule.
2. Signing something based on not real facts. 
3. Not signing a valid signature request.


# Use Cases


1. First party bridges: token X exists on chain Y. Use this protocol to create bridged token X on other chains.

2. Copycat oracles: oracle X exists on chain Y. Use this protocol create copycat oracles in other chains.

3. Account abstraction stuff


# Alternatives

## LitProtocol

Mixes facts and conditions

Uses its own programming language, instead of EVM for the conversion from facts to message to sign. 


## Using ZK proofs instead of MPC

Podríamos usar ZK proofs para los facts en lugar de MPC? Qué ventajas tendría? Ahí ya no generaríamos una signature sino una serie de pruebas? Cómo sería?




