const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleDEX - Full Coverage Test", function () {
  let dex, tokenA, tokenB, owner, user;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy test tokens
    const TokenA = await ethers.getContractFactory("TokenA");
    const TokenB = await ethers.getContractFactory("TokenB");
    tokenA = await TokenA.deploy(1000000);
    tokenB = await TokenB.deploy(1000000);

    // Mint initial tokens
    await tokenA.mint(owner.address, ethers.parseEther("10000"));
    await tokenB.mint(owner.address, ethers.parseEther("10000"));
    await tokenA.mint(user.address, ethers.parseEther("1000"));
    await tokenB.mint(user.address, ethers.parseEther("1000"));

    // Deploy DEX contract
    const SimpleDEX = await ethers.getContractFactory("SimpleDEX");
    dex = await SimpleDEX.deploy(tokenA.target, tokenB.target);

    // Add initial liquidity
    const amountA = ethers.parseEther("100");
    const amountB = ethers.parseEther("200");
    await tokenA.connect(owner).approve(dex.target, amountA);
    await tokenB.connect(owner).approve(dex.target, amountB);
    await dex.connect(owner).addLiquidity(amountA, amountB);
  });

  describe("Core Functionality", function () {
    it("Should initialize with correct token addresses", async function () {
      expect(await dex.tokenA()).to.equal(tokenA.target);
      expect(await dex.tokenB()).to.equal(tokenB.target);
    });

    it("Should correctly identify the owner", async function () {
      expect(await dex.owner()).to.equal(owner.address);
    });
  });

  describe("Liquidity Operations", function () {
    it("Should prevent non-owners from adding liquidity", async function () {
      await expect(
        dex.connect(user).addLiquidity(1, 1)
      ).to.be.revertedWithCustomError(dex, "OwnableUnauthorizedAccount");
    });

    it("Should remove liquidity (owner only)", async function () {
      const amountA = ethers.parseEther("50");
      const amountB = ethers.parseEther("100");

      await expect(dex.connect(owner).removeLiquidity(amountA, amountB))
        .to.emit(dex, "LiquidityRemoved")
        .withArgs(owner.address, amountA, amountB);
    });
  });

  describe("Swap Operations", function () {
    it("Should swap tokenA for tokenB", async function () {
      const amountIn = ethers.parseEther("10");
      await tokenA.connect(user).approve(dex.target, amountIn);

      const reserveA = await dex.reserveA();
      const reserveB = await dex.reserveB();
      const expectedAmountOut = (amountIn * reserveB) / (reserveA + amountIn);

      await expect(dex.connect(user).swapAforB(amountIn))
        .to.emit(dex, "Swap")
        .withArgs(user.address, tokenA.target, amountIn, expectedAmountOut);
    });

    it("Should swap tokenB for tokenA", async function () {
      const amountIn = ethers.parseEther("5");
      await tokenB.connect(user).approve(dex.target, amountIn);

      const reserveA = await dex.reserveA();
      const reserveB = await dex.reserveB();
      const expectedAmountOut = (amountIn * reserveA) / (reserveB + amountIn);

      await expect(dex.connect(user).swapBforA(amountIn))
        .to.emit(dex, "Swap")
        .withArgs(user.address, tokenB.target, amountIn, expectedAmountOut);
    });
  });

  describe("Price Calculations", function () {
    it("Should return correct price for tokenA", async function () {
      const price = await dex.getPrice(tokenA.target);
      expect(price).to.be.gt(0);
    });

    it("Should return correct price for tokenB", async function () {
      const price = await dex.getPrice(tokenB.target);
      expect(price).to.be.gt(0);
    });
  });

  describe("Edge Cases", function () {
    it("Should prevent swap when no liquidity", async function () {
      const emptyDex = await ethers.deployContract("SimpleDEX", [tokenA.target, tokenB.target]);
      await tokenA.connect(user).approve(emptyDex.target, 1);
      await expect(emptyDex.connect(user).swapAforB(1))
        .to.be.revertedWith("No liquidity");
    });

    it("Should prevent adding zero liquidity", async function () {
      await expect(dex.connect(owner).addLiquidity(0, 1))
        .to.be.revertedWith("Invalid amounts");
    });
  });
});