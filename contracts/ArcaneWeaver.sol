// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/Ownable.sol";
import "./erc20/BoringERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/EnumerableSet.sol";

contract ArcaneWeaver is Ownable, ReentrancyGuard
{
    using SafeMath for uint256;
    using BoringERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
}