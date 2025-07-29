async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with address:", deployer.address);

  // Tokens deploys
  const TokenA = await ethers.getContractFactory("TokenA");
  const TokenB = await ethers.getContractFactory("TokenB");
  const tokenA = await TokenA.deploy(1000000);
  const tokenB = await TokenB.deploy(1000000);

  // Dex deploy
  const SimpleDEX = await ethers.getContractFactory("SimpleDEX");
  const dex = await SimpleDEX.deploy(tokenA.target, tokenB.target);

  console.log("Contracts address:");
  console.log("TokenA:", tokenA.target);
  console.log("TokenB:", tokenB.target);
  console.log("SimpleDEX:", dex.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});