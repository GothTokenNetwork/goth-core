// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEssenceFarm 
{
    function potionMaster () external view returns (address);

    function farmAddress (uint256 farmId) external view returns (address);

    function farmerInfo (uint256 farmId) external view returns (uint256[3] memory);

    function farmCount () external view returns (uint256);

    function userLevels () external view returns (address);

}