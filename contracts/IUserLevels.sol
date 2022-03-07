// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IUserLevels
{
    function isAccessor (address accessor) external view returns (string memory);

    function userInfo () external view returns (uint256[3] memory);

    function incrementExperience (address sender, uint256 amount) external;

    function forceLevelUpdate (address user) external;

    function initializeUser (address user) external; 

    function totalUserLevels () external view returns (uint256);

    function levelOf (address user) external view returns (uint256);

    function potionMaster () external view returns (address);
}