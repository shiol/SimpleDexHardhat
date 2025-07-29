// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenA is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Token A", "TKA") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        _mint(to, amount * 10 ** decimals());
    }

    function burn(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        _burn(msg.sender, amount * 10 ** decimals());
    }
}