// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "../../utils/Ownable.sol";
import "../../utils/Sender.sol";
import"../../utils/ReentrancyGuard.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/SafeMath.sol";
import "../../erc20/SafeERC20.sol";
import "../../erc20/IERC20.sol";

contract GothSlots is Ownable, Sender, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private devAddress;

    bool private avaxPrizeActive;

    uint256 private gothSpinCost;
    uint256 private avaxSpinCost;
    uint256 private gothPayoutThreshold;
    uint256 private avaxPayoutThreshold;

    mapping(uint8 => uint256) internal prizeValues;
    public IERC20 goth;

    struct PlayerInfo { 
        uint256 accumulatedGOTH; 
        uint256 accumulatedAVAX; 
        bytes32 spinsRemaining;  
    } 

    mapping(address => PlayerInfo) internal players; 

    event SetDevAddress(address newDevAddress);
    event WinningMatch(uint256 payout);

    constructor (IERC20 goth_, address devAddress_)
    {
        devAddress = devAddress_;
        goth = goth_;
    }

    function devAddress () external view returns (address)
    {
        return devAddress;
    }

    function setDevAddress (address newDevAddress) external onlyOwner returns (bool)
    {
        devAddress = newDevAddress;
        emit SetTreasury(newDevAddress);
    }

    function purchaseSpins (uint8 count) external payable nonReentrant returns (bool)
    {
        if (avaxPrizeActive)
        {
            require(msg.value >= count.mul(avaxSpinCost), "purchaseSpins: not enough avax");
        }
        else
        {
            require(goth.balanceOf(msg.sender) >= count.mul(gothSpinCost), "purchaseSpins: not enough goth");   
            goth.transferFrom(msg.sender, address(this), count.mul(gothSpinCost));      
        }

        require(msg.value >= _spinCost, "purchaseSpins: not enough avax");
        return true;
    }

    function validateResult (uint256[3][3] calldata results) public pure returns (uint256[3][3] memory)
    {
        uint256[3][3] memory matches; 

        for (uint row = 0; row < 3; row++)
        {
            if (results[row][0] == results[row][1] && results[row][1] == results[row][2])
            {
                matches[row][0] = results[row][0];
                matches[row][1] = results[row][0];
                matches[row][2] = results[row][0];
            }

            if (row == 0)
            {
                if (results[row][0] == results[row+1][1] && results[row+1][1] == results[row+2][2])
                {
                    matches[row][0] = results[row][0];
                    matches[row+1][1] = results[row][0];
                    matches[row+2][2] = results[row][0];
                }
            }

            if (row == 0)
            {
                if (results[row+2][2] == results[row+1][1] && results[row+1][1] == results[row][0])
                {
                    matches[row+2][0] = results[row+2][2];
                    matches[row+1][1] = results[row+2][2];
                    matches[row][2] = results[row+2][2];
                }
            }
        }

        return matches;
    }

    function () public payable {
        revert(); 
    } 
}