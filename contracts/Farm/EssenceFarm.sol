// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./EssenceERC20.sol";
import "../Utils/SafeMath.sol";

contract EssenceFarm {
    using SafeMath for uint256;

    // Earth Essence = 0
    // Air Essence = 1
    // Spirit Essence = 2
    // Water Essence = 3
    // Fire Essence = 4
    EssenceERC20[5] private _essenceFarms;

    IERC20 private immutable _gothPair;

    struct Farmer { uint256 amount; uint256 lastClaim; }
    struct User { uint256 totalStaked; uint256 totalEssence; uint256 bonus; uint256 nextUnlock; }

    mapping(uint8 => mapping(address => Farmer)) private farmers;
    mapping(address => User) private users;

    // EVENTS //
    event FarmEntered(address sender, uint256 amount, uint8 essenceType);
    event FarmLeft(address sender, uint256 amount, uint8 essenceType);

    // MODIFIERS //
    modifier farmRequired(uint8 farmId) {
        require(farmId <= 4, 'invalid essence farm id');
        _;
    }

    // CONSTRUCTOR //
    constructor (IERC20 gothPair_)
    {
        _gothPair = gothPair_;
        _essenceFarms[0] = new EssenceERC20('Earth Essence', 'EARTH', address(this));
        _essenceFarms[1] = new EssenceERC20('Air Essence', 'AIR', address(this));
        _essenceFarms[2] = new EssenceERC20('Spirit Essence', 'SPIRIT', address(this));
        _essenceFarms[3] = new EssenceERC20('Water Essence', 'WATER', address(this));
        _essenceFarms[4] = new EssenceERC20('Fire Essence', 'FIRE', address(this));
    }

    // EXTERNAL FUNCTIONS //
    function enterFarm (uint256 amount, uint8 farmId) public virtual returns (bool)
    {
        _enterFarm(msg.sender, amount, farmId);
        return true;
    }

    function leaveFarm (uint256 amount, uint8 farmId) public virtual returns (bool)
    {
        _leaveFarm(msg.sender, amount, farmId);
        return true;
    }

    function claimEssence (uint8 farmId) public virtual returns (bool)
    {
        _claimEssence(msg.sender, farmId);
        return true;
    }

    // INTERNAL FUNCTIONS //
    function _calculateUserInfo (address ofAddress) internal virtual
    {
        User memory user = users[ofAddress];

        user.totalStaked = _getAllFarmTotal(ofAddress);
        user.totalEssence = _getAllEssenceAccumulated(ofAddress);
        user.bonus = _calculateBonus(ofAddress);
    }

    function _enterFarm (address sender, uint256 amount, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(_gothPair.balanceOf(sender) >= amount, 'not enough gsl tokens');

        Farmer memory farmer = farmers[farmId][sender];
        _claimEssence(sender, farmId);
        farmer.amount.add(amount);
        _gothPair.transferFrom(sender, address(this), amount);
        emit FarmEntered(sender, amount, farmId);
    }

    function _leaveFarm (address sender, uint256 amount, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(farmers[farmId][sender].amount <= amount, 'attempted to withdraw more than what there is');

        Farmer memory farmer = farmers[farmId][sender];
        farmer.amount.sub(amount);
        _gothPair.transferFrom(address(this), sender, amount);
        emit FarmLeft(sender, amount, farmId);
    }

    function _claimEssence (address sender, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(block.timestamp > farmers[farmId][sender].lastClaim, 'claim from the future');

        Farmer memory farmer = farmers[farmId][sender];
        uint256 essence = _calculateEssence(sender, farmer.lastClaim);
     
        _essenceFarms[farmId].mint(sender, essence);

        farmer.lastClaim = block.timestamp;
    }

    function _calculateEssence (address ofAddress, uint256 lastClaim) internal virtual returns (uint256)
    {
        uint256 secondsPast = block.timestamp - lastClaim;
        return secondsPast.mul(_calculateBonus(ofAddress));
    }

    function _calculateBonus (address ofAddress) internal virtual returns (uint256)
    {
        /// Needs refactoring
        uint256 bonus = _getAllFarmTotal(ofAddress).div(10000);
        bonus.add(1);
        users[ofAddress].bonus = bonus;
        return bonus;
    }

    function _getAllFarmTotal (address ofAddress) internal virtual returns (uint256)
    {
        uint256 allFarmTotal = 0;
        for (uint8 i = 0; i < 5; i++) {
            allFarmTotal.add(farmers[i][ofAddress].amount);
        }
        return allFarmTotal;
    }

    function _getAllEssenceAccumulated (address ofAddress) internal virtual returns (uint256)
    {
        uint256 allEssenceAccumulated = 0;
        for (uint8 i = 0; i < 5; i++) {
            allEssenceAccumulated.add(_calculateEssence(ofAddress, farmers[i][ofAddress].lastClaim));
        }
        return allEssenceAccumulated;
    }
}