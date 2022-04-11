// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../erc20/ERC20.sol";
import "../utils/SafeMath.sol";

// SigilStake is a modified version of JoeBar.sol that is from Trader Joe's GitHub joe-core repository, found here;
// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/JoeBar.sol.
//
// This contract handles swapping to and from xSIGIL, SIGIL's staking token.
contract SigilStake is ERC20("X SIGIL", "xSIGIL") {
    using SafeMath for uint256;
    IERC20 public sigil;

    // Define the SIGIL token contract
    constructor(IERC20 _sigil) {
        sigil = _sigil;
    }

    // Locks SIGIL and mints xSIGIL
    function enter(uint256 _amount) public {
        // Gets the amount of SIGIL locked in the contract
        uint256 totalSigil = sigil.balanceOf(address(this));
        // Gets the amount of xSIGIL in existence
        uint256 totalShares = totalSupply();
        // If no xSIGIL exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSigil == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xSIGIL the SIGIL is worth. The ratio will change overtime, as xSIGIL is burned/minted and SIGIL deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalSigil);
            _mint(msg.sender, what);
        }
        // Lock the SIGIL in the contract
        sigil.transferFrom(msg.sender, address(this), _amount);
    }

    // Unlocks the staked + gained SIGIL and burns xSIGIL
    function leave(uint256 _share) public {
        // Gets the amount of xSIGIL in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of SIGIL the xSIGIL is worth
        uint256 what = _share.mul(sigil.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        sigil.transfer(msg.sender, what);
    }
}