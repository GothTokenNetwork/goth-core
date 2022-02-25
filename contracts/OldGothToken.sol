// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./ERC20/ERC20.sol";
import "./ERC20/ERC20Burnable.sol";

contract OldGothToken is ERC20, ERC20Burnable 
{
    constructor() ERC20("GOTH Token", "GOTH") 
    {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}