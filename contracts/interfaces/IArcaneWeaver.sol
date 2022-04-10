// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../erc20/SafeERC20.sol";

interface IArcaneWeaver
{
    struct Weaver {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 accrued; // Reward debt. See explanation below.
    }

    struct ArcaneFarm {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocationPoints; // How many allocation points assigned to this poolInfo. SUSHI to distribute per block.
        uint256 lastRewardTime; // Last block timestamp that SUSHI distribution occurs.
        uint256 accSigilPerShare; // Accumulated SIGIL per share, times 1e18. See below.
    }

    function arcaneFarm(uint256 farmId) external view returns (ArcaneFarm memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _farmId, uint256 _amount) external;
}