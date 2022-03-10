// SPDX-License-Identifier: GPL-3.0
pragma solidity ^8.7.0;

import "../../utils/Ownable.sol";
import "../../utils/Sender.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/SafeMath.sol";
import "../../erc20/SafeERC20.sol";
import "../../erc20/IERC20.sol";

contract GothSlots, Ownable, Sender, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private _treasury;
    uint256 private _spinCost;



    event SetTreasury(address newTreasury);
    event WinningMatch(uint256 payout);

    constructor (address treasury_)
    {
        _treasury = treasury_;
    }

    function treasury () external view override returns (address)
    {
        return _treasury;
    }

    function setTreasury (address newTreasury) external onlyOwner returns (bool)
    {
        _treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }

    function treasury () external view override returns (address)
    {
        return _treasury;
    }

    function setTreasury (address newTreasury) external onlyOwner returns (bool)
    {
        _treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }

    function requestSpin () external payable returns (bool success)
    {
        success = false;
        require(msg.value >= _spinCost, "requestSpin: not enough avax");
        return true;
    }

    function validateResult (uint256[3][2] results) external onlyOwner
    {
        uint256[2] memory reel1 = results[0];
        uint256[2] memory reel2 = results[1];
        uint256[2] memory reel3 = results[2];

        // Straight Matches
        if (reel1[0] == reel2[0] && reel2 == reel3[0])
        {
            // Matched Symbols
            if (reel1[1] == reel2[1] && reel2 == reel3[1])
            {
                // Matched Line
                if (reel1[1] == 0)
                {
                    // Bottom Line
                   emit WinningMatch(payout);
                }

                if (reel1[1] == 1)
                {
                    // Middle Line
                    emit WinningMatch(payout);
                }

                if (reel1[1] == 2)
                {
                    // Top Line
                    emit WinningMatch(payout);
                }
            }
        }

        // Diagonal Matches
        if (reel1[0] == reel2[0] && reel2 == reel3[0])
        {
            // Matched Symbols
            if (reel1[1] == 0 && reel2[1] == 1 && reel3[1] == 2)
            {   
                // Bottom Right To Top Left Match
                emit WinningMatch(payout);
            }

            if (reel1[1] == 2 && reel2[1] == 1 && reel3[1] == 0)
            {   
                // Top Right To Bottom Left Match
                emit WinningMatch(payout);
            }
        }
    }
}