// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "../ERC20/IERC20.sol";
import "../ERC20/ERC20.sol";
import "../ERC20/SafeERC20.sol";
import "../Pairs/IGothPair.sol";
import "../Utils/SafeMath.sol";
import "../Utils/TransferHelper.sol";

contract EssenceFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Essence Farms
    IERC20[5] private _essenceFarms;
    // Earth Essence = 0
    // Air Essence = 1
    // Spirit Essence = 2
    // Water Essence = 3
    // Fire Essence = 4

    // GothPair interface
    IERC20 private immutable _gothPair;

    // User farm info
    struct Farmer { uint256 totalStaked; uint256 accruedEssence; uint256 lastClaim; }
    // User info
    struct User { uint256 totalStaked; uint256 totalEssence; uint256 level; uint256 nextUnlock; }

    // User farm mapping
    mapping(uint8 => mapping(address => Farmer)) private farmers;
    // User mapping
    mapping(address => User) private users;

    // Contract owner
    address _owner;
    // Gloabl bonus mod
    uint256 private _bonusMod;

    // EVENTS //
    event EnterFarm(address sender, uint256 amount, uint8 farmId);
    event LeaveFarm(address sender, uint256 amount, uint8 farmId);
    event TransferOwner(address newOwner);
    event SetBonusMod(uint256 newbonusMod);

    // MODIFIERS //
    modifier farmRequired(uint8 farmId) {
        require(farmId <= 4, 'invalid essence farm id');
        _;
    }

    modifier onlyOwner () {
        require(msg.sender == _owner);
        _;
    }

    // CONSTRUCTOR //
    constructor (IERC20 gothPair_)
    {
        // Sets contract owner/controller and the GothPair (GSL token contract)
        _owner = msg.sender;
        _gothPair = gothPair_;
        // Deploys all essence farms and assigns them to the array
        _essenceFarms[0] = new ERC20('Earth Essence', 'EARTH');
        _essenceFarms[1] = new ERC20('Air Essence', 'AIR');
        _essenceFarms[2] = new ERC20('Spirit Essence', 'SPIRIT');
        _essenceFarms[3] = new ERC20('Water Essence', 'WATER');
        _essenceFarms[4] = new ERC20('Fire Essence', 'FIRE');
    }

    function owner () external view returns (address) { 
        return _owner; 
    }

    function gothPair () external view returns (address) { 
        return address(_gothPair); 
    }

    function totalStaked () external view returns (uint256) { 
        return users[msg.sender].totalStaked; 
    }

    function totalEssence () external view returns (uint256) { 
        return users[msg.sender].totalEssence; 
    }

    function bonus () external view returns (uint256) { 
        return users[msg.sender].bonus; 
    }

    function nextUnlock () external view returns (uint256) { 
        return users[msg.sender].nextUnlock; 
    }

    function farmBalance (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].amount; 
    }

    function farmLastClaim (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].lastClaim; 
    }

    function essenceFarm (uint8 farmId) external view farmRequired(farmId) returns (address) {
        return address(_essenceFarms[farmId]);
    }   

    function transferOwnership (address newOwner) external onlyOwner {
        _owner = newOwner;
        emit TransferOwner(_owner);
    }

    function setBonusMod (uint256 bonusMod) external onlyOwner {
        _bonusMod = bonusMod;
        emit SetBonusMod(_bonusMod);
    }

    function enterFarm (uint256 amount, uint8 farmId) public farmRequired(farmId)
    {
        Farmer storage farmer = farmers[farmId][msg.sender];

        if (calculateEssence(msg.sender, farmId) > 0)
        {
            // Claim essence
        }

        farmer.amount = amount;
        farmer.lastClaim = block.timestamp;
        _gothPair.safeTransferFrom(address(msg.sender), address(_essenceFarms[farmId]), amount);
        emit EnterFarm(address(msg.sender), amount, farmId);
    }

    function calculateEssence (address sender, uint8 farmId) private view farmRequired(farmId) returns (uint256)
    {
        Farmer storage farmer = farmers[farmId][sender];
        if (farmer.amount > 0 && farmer.lastClaim > block.timestamp)
        {
            return farmer.amount.div(1000000000000000000).mul(users[sender].level.mul(_bonusMod)).mul(block.timestamp.sub(farmer.lastClaim));
        }
        else
        {
            return 0;
        }
    }  
}