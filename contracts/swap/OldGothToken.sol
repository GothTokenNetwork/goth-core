// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../erc20/ERC20.sol";
import "../erc20/ERC20Burnable.sol";

contract OldGothToken is ERC20, ERC20Burnable 
{
    constructor() ERC20("GOTH Token", "GOTH") 
    {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}