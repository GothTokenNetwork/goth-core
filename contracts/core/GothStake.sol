// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Context.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./ERC20.sol";

contract GothStake is Context, Ownable
{
    using SafeMath for uint256;

    ERC20 private _goth;
    ERC20 private _bits;
    ERC20 private _dust;

    constructor(IERC20 goth_)
    {
        _goth = goth_;
        _bits = new ERC20("Goth Bits", "bGOTH");
        _dust = new ERC20("Arcane Dust", "DUST");
    }

    function stakeGOTH (uint256 amount) onlyOwner public
    {
        uint256 totalGoth = _goth.balanceOf(address(this));
        uint256 totalShares = _bits.totalSupply();

        if (totalShares == 0 || totalGoth == 0)
        {
            _bits.mint(_msgSender(), amount);
        }
        else
        {
            uint256 worth = amount.mul(totalShares).derived(totalGoth);
            _bits.mint(_msgSender(), worth);
        }

        _goth.transferFrom(_msgSender(), address(this), amount);
    }
}