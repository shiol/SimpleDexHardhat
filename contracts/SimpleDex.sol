// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ISimpleDEX.sol";

contract SimpleDEX is Ownable, ReentrancyGuard, ISimpleDEX {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external override onlyOwner nonReentrant {
        // Checks
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(tokenA.allowance(msg.sender, address(this)) >= amountA, "Insufficient TokenA allowance");
        require(tokenB.allowance(msg.sender, address(this)) >= amountB, "Insufficient TokenB allowance");

        // Effects
        reserveA += amountA;
        reserveB += amountB;

        // Interactions
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "TokenB transfer failed");

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external override onlyOwner nonReentrant {
        // Checks
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        // Effects
        reserveA -= amountA;
        reserveB -= amountB;

        // Interactions
        require(tokenA.transfer(msg.sender, amountA), "TokenA transfer failed");
        require(tokenB.transfer(msg.sender, amountB), "TokenB transfer failed");

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external override nonReentrant {
        // Checks
        require(amountAIn > 0, "Invalid amount");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        require(tokenA.allowance(msg.sender, address(this)) >= amountAIn, "Insufficient TokenA allowance");

        uint256 amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        require(amountBOut <= reserveB, "Insufficient reserve B");

        // Effects
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // Interactions
        require(tokenA.transferFrom(msg.sender, address(this), amountAIn), "TokenA transfer failed");
        require(tokenB.transfer(msg.sender, amountBOut), "TokenB transfer failed");

        emit Swap(msg.sender, address(tokenA), amountAIn, amountBOut);
    }

    function swapBforA(uint256 amountBIn) external override nonReentrant {
        // Checks
        require(amountBIn > 0, "Invalid amount");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        require(tokenB.allowance(msg.sender, address(this)) >= amountBIn, "Insufficient TokenB allowance");

        uint256 amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        require(amountAOut <= reserveA, "Insufficient reserve A");

        // Effects
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // Interactions
        require(tokenB.transferFrom(msg.sender, address(this), amountBIn), "TokenB transfer failed");
        require(tokenA.transfer(msg.sender, amountAOut), "TokenA transfer failed");

        emit Swap(msg.sender, address(tokenB), amountBIn, amountAOut);
    }

    function getPrice(address _token) external view override returns (uint256) {
        if (_token == address(tokenA)) {
            return (reserveB * 10**18) / reserveA;
        } else if (_token == address(tokenB)) {
            return (reserveA * 10**18) / reserveB;
        } else {
            revert("Invalid token address");
        }
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "No liquidity");

        // dy = y - xy / (x + dx)
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        return numerator / denominator;
    }
}