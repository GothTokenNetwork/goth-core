// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./SafeMath.sol";

library GothMath {
    using SafeMath for uint256;

    function getPercent (uint256 min, uint256 max) public pure returns (uint256)
    {
        return min.mul(1000).div(max).add(5).div(10);
    }

}