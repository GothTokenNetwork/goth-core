// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../erc20/ERC20.sol";
import "../utils/SafeMath.sol";

// GothStake is a modified version of JoeBar.sol that is from Trader Joe's GitHub joe-core repository, found here;
// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/JoeBar.sol.
//
// This contract handles swapping to and from bGOTH, GOTH's staking token.
contract GothStake is ERC20("GOTH Bits", "bGOTH") {
    using SafeMath for uint256;
    IERC20 public goth;

    // Define the GOTH token contract
    constructor(IERC20 _goth) {
        goth = _goth;
    }

    // Locks GOTH and mints bGOTH
    function enter(uint256 _amount) public {
        // Gets the amount of GOTH locked in the contract
        uint256 totalGoth = goth.balanceOf(address(this));
        // Gets the amount of bGOTH in existence
        uint256 totalShares = totalSupply();
        // If no bGOTH exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalGoth == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of bGOTH the GOTH is worth. The ratio will change overtime, as bGOTH is burned/minted and GOTH deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalGoth);
            _mint(msg.sender, what);
        }
        // Lock the GOTH in the contract
        goth.transferFrom(msg.sender, address(this), _amount);
    }

    // Unlocks the staked + gained GOTH and burns bGOTH
    function leave(uint256 _share) public {
        // Gets the amount of bGOTH in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of GOTH the bGOTH is worth
        uint256 what = _share.mul(goth.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        goth.transfer(msg.sender, what);
    }
}