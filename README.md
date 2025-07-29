# Sample Hardhat Project

This project demonstrates a basic Hardhat use case.

Create .env file:

ALCHEMY_API_KEY=your_alchemy_key_here

PRIVATE_KEY=your_private_key_without_0x

Try running some of the following tasks:

```shell
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.js
```

Definitive deploy:

```shell
npx hardhat run scripts/deploy.js --network sepolia
```


Or try localhost.
Console 1:
```shell
npx hardhat node
```

Console 2:
```shell
npx hardhat run scripts/deploy.js --network localhost
```
