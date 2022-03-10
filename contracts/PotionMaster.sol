// SPDX-License-Identifier: GPL-3.0
pragma solidity ^8.7.0;

import "../utils/Ownable.sol";
import "../utils/Sender.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/TransferHelper.sol";
import "../utils/SafeMath.sol";
import "../erc20/SafeERC20.sol";
import "../erc20/IERC20.sol";

contract PotionMaster, Ownable, Sender, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    
}