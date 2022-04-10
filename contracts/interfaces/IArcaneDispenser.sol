// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../erc20/IERC20.sol";

interface IArcaneDispenser
{
    function onSigilReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}