// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleDEX {
    function addLiquidity(uint256 amountA, uint256 amountB) external;
    function swapAforB(uint256 amountAIn) external;
    function swapBforA(uint256 amountBIn) external;
    function removeLiquidity(uint256 amountA, uint256 amountB) external;
    function getPrice(address _token) external view returns (uint256);
}