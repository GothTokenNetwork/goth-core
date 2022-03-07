// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./utils/Ownable.sol";
import "./IUserLevels.sol";
import "./utils/SafeMath.sol";

contract UserLevels is IUserLevels, Ownable
{
    using SafeMath for uint256;
    
    struct Effect { 
        uint256 value; 
        uint256 expires; 
        string potionId; 
    }

    struct User { 
        uint256 experience; 
        uint256 level; 
        uint256 experienceRequired;
        Effect expBoost;
    }

    mapping(address => User) private _users;
    mapping(address => uint256) private _accessors;
    uint256 private _totalUserLevels;
    address private _potionMaster;

    event ApplyExpBoost(address user, uint256 boost, uint256 expires, string potionId);
    event IncrementExperience(address sender, uint256 experience, uint256 level);
    event SetAccessor(address accessor);
    event RevokeAccessor(address revoked);
    event LevelUp(address user, uint256 level, uint256 experienceRequired);
    event PotionEffectExpired(address user, string potionId);
    event SetPotionMaster(address newPotionMaster);

    modifier onlyPotionMaster() {
        require(_potionMaster == _msgSender(), "onlyPotionMaster: caller is not the potion master");
        _;
    }
    
    constructor () { }

    function setAccessor (address toSet) external onlyOwner()
    {
        _accessors[toSet] = 1;
        emit SetAccessor(toSet);
    }

    function revokeAccessor (address toRevoke) external onlyOwner()
    {
        _accessors[toRevoke] = 0;
        emit RevokeAccessor(toRevoke);
    }

    function isAccessor (address accessor) external view override returns (string memory)
    {
        return _accessors[accessor] == 0 ? "false" : "true";
    }

    function setPotionMaster (address newPotionMaster) external onlyOwner {
        _potionMaster = newPotionMaster;
        emit SetPotionMaster(_potionMaster);
    }

    function potionMaster () external view override returns (address) {
        return _potionMaster;
    }

    function userInfo () external view override returns (uint256[3] memory) {
        User memory user = _users[msg.sender];
        uint256[3] memory info = [user.experience, user.level, user.experienceRequired];
        return info;
    }

    function levelOf (address user) external view override returns (uint256) {
        return _users[user].level;
    }

    function totalUserLevels () external view override returns (uint256) {
        return _totalUserLevels;
    }

    function incrementExperience (address sender, uint256 amount) external override
    {
        require(_accessors[msg.sender] == 1, "incrementExperience: caller is not an accessor");
        User storage user = _users[sender];
        uint256 exp = amount.div(1e12);
        user.experience = user.experience.add(calculateExpBoost(exp, sender));
        calculateLevel(sender);
        emit IncrementExperience(sender, exp, user.level);
    } 

    function calculateLevel (address sender) internal
    {
        User storage user = _users[sender];    
        if (user.experience >= user.experienceRequired)
        {
            user.level = user.level.add(1);
            _totalUserLevels.add(1);
            user.experienceRequired = user.experienceRequired.mul(12500 - (user.level.mul(225).div(100))).div(10000);
            emit LevelUp(sender, user.level, user.experienceRequired);
        }
    }

    function forceLevelUpdate (address user) external override
    {
        calculateLevel(user);
    } 

    function calculateExpBoost (uint256 expIn, address sender) internal returns (uint256)
    {
        User storage user = _users[sender];


        if (block.timestamp < user.expBoost.expires)
        {
            uint256 bonus = expIn.mul(user.expBoost.value).div(100);
            return expIn.add(bonus);
        }
        else
        {
            user.expBoost.value = 1;

            if (bytes(user.expBoost.potionId).length == 0)
            {
                emit PotionEffectExpired(sender, user.expBoost.potionId);
                user.expBoost.potionId = "";
            }
            return expIn;
        }
    }

    function applyExpBoost (address sender, uint256 boost, uint256 expires, string memory potionId) public onlyPotionMaster
    {
        require(boost > 0, "applyExpBoost: boost cannot be 0");
        User storage user = _users[sender];
        user.expBoost.value = boost;
        user.expBoost.expires = expires;
        user.expBoost.potionId = potionId;
        emit ApplyExpBoost(sender, boost, expires, potionId);
    } 

    function initializeUser (address sender) external override
    {
        User storage user = _users[sender];
        if (user.level == 0)
        {
            user.experience = 0;
            user.experienceRequired = 50 * 1e18;
            _totalUserLevels += 1;
            user.level = 1;
        }
    }
}