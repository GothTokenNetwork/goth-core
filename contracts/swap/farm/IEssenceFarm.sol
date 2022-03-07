// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IEssenceFarm 
{
    function baseMintRate () external view returns (uint256);

    function potionMaster () external view returns (address);

    function emergencyBenefactor () external view returns (address);

    function farmAddress (uint256 farmId) external view returns (address);

    function farmerInfo (uint256 farmId) external view returns (uint256[3] memory);

    function farmCount () external view returns (uint256);

    function userLevels () external view returns (address);

}