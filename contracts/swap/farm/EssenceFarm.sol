// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "../../erc20/IERC20.sol";
import "./EssenceERC20.sol";
import "../../erc20/SafeERC20.sol";
import "../pairs/IGothPair.sol";
import "../../utils/SafeMath.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Ownable.sol";
import "../../utils/Sender.sol";

contract EssenceFarm is Ownable, Sender {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Essence Farms
    EssenceERC20[5] private _essenceFarms;
    // Earth Essence = 0
    // Air Essence = 1
    // Spirit Essence = 2
    // Water Essence = 3
    // Fire Essence = 4

    // GothPair interface
    IERC20 private _gothPair;

    // User farm info
    struct Farmer { uint256 totalStaked; uint256 accruedEssence; uint256 lastInteraction; }
    // User info
    struct User { uint256 experience; uint256 level; uint256 nextUnlock; }

    // User farm mapping
    mapping(uint8 => mapping(address => Farmer)) private farmers;
    // User mapping
    mapping(address => User) private users;

    // Total of all user levels
    uint256 private _totalUserLevels;

    // EVENTS //
    event Deposit(address sender, uint256 amount, uint8 farmId);
    event Withdraw(address sender, uint256 amount, uint8 farmId);
    event EssenceClaimed(address sender, uint256 amount, uint8 farmId);

    // MODIFIERS //
    modifier farmRequired(uint8 farmId) {
        require(farmId <= 4, 'invalid essence farm id');
        _;
    }

    // CONSTRUCTOR //
    constructor (IERC20 gothPair_)
    {
        _gothPair = gothPair_;
        // Deploys all essence farms and assigns them to the array
        _essenceFarms[0] = new EssenceERC20('Earth Essence', 'EARTH');
        _essenceFarms[1] = new EssenceERC20('Air Essence', 'AIR');
        _essenceFarms[2] = new EssenceERC20('Spirit Essence', 'SPIRIT');
        _essenceFarms[3] = new EssenceERC20('Water Essence', 'WATER');
        _essenceFarms[4] = new EssenceERC20('Fire Essence', 'FIRE');
    }

    function gothPair () external view returns (address) { 
        return address(_gothPair); 
    }

    function farmTotalStaked (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].totalStaked; 
    }

    function farmlastInteraction (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].lastInteraction; 
    }

    function essenceFarm (uint8 farmId) public view farmRequired(farmId) returns (address) {
        return address(_essenceFarms[farmId]);
    }

    function essenceFarmBalance (uint8 farmId) external view farmRequired(farmId) returns (uint256) {
        return _gothPair.balanceOf(address(_essenceFarms[farmId]));
    }

    function userInfo () external view returns (uint256[3] memory) {
        User memory user = users[msg.sender];
        uint256[3] memory info = [user.experience, user.level, user.nextUnlock];
        return info;
    }   

    function farmInfo (uint8 farmId) external view farmRequired(farmId) returns (uint256[3] memory) {
        Farmer memory farm = farmers[farmId][msg.sender];
        uint256[3] memory info = [farm.totalStaked, farm.accruedEssence, farm.lastInteraction];
        return info;
    }   

    function deposit (uint256 amount, uint8 farmId) public farmRequired(farmId)
    {
        require(_gothPair.balanceOf(msg.sender) >= amount, "not enough GSL tokens");   

        Farmer storage farmer = farmers[farmId][msg.sender];
        uint256 accruedEssence = calculateEssenceSincelastInteraction(msg.sender, farmId);
        
        if (farmer.totalStaked > 0)
        {
            farmer.accruedEssence = accruedEssence;
        }

        farmer.totalStaked = farmer.totalStaked + amount;
        farmer.lastInteraction = block.timestamp;
        TransferHelper.safeTransferFrom(address(_gothPair), msg.sender, address(_essenceFarms[farmId]), amount);
        emit Deposit(msg.sender, amount, farmId);
    }

    function withdraw (uint256 amount, uint8 farmId) public farmRequired(farmId)
    {
        Farmer storage farmer = farmers[farmId][msg.sender];
        require(farmer.totalStaked >= amount, "you do not have that many GSL tokens staked in this farm");

        if (farmer.totalStaked == amount)
        {
            claimEssence(msg.sender, farmId);
        }
        else
        {
            farmer.accruedEssence = farmer.accruedEssence + calculateEssenceSincelastInteraction(msg.sender, farmId);
        }

        farmer.totalStaked = farmer.totalStaked - amount;
        farmer.lastInteraction = block.timestamp;
        _essenceFarms[farmId].withdrawGSLTo(msg.sender, amount);
        emit Withdraw(msg.sender, amount, farmId);
    }

    function claimEssence (address sender, uint8 farmId) public farmRequired(farmId)
    {
        Farmer storage farmer = farmers[farmId][sender];
        require(farmer.totalStaked > 0, "you do not have any GSL tokens staked");

        uint256 reward = farmer.accruedEssence + calculateEssenceSincelastInteraction(sender, farmId);
        farmer.accruedEssence = 0;
        farmer.lastInteraction = block.timestamp;
        _essenceFarms[farmId].mint(sender, reward);
        emit EssenceClaimed(msg.sender, reward, farmId);
    }

    function calculateEssenceSincelastInteraction (address sender, uint8 farmId) private view farmRequired(farmId) returns (uint256)
    {
        Farmer storage farmer = farmers[farmId][sender];
        if (farmer.lastInteraction < block.timestamp)
        {
            uint256 level = 1;
            uint256 allLevels = 1;
            uint256 time = block.timestamp.sub(farmer.lastInteraction);

            //return farmer.totalStaked.div(1000000000).mul(users[sender].level.mul(_totalUserLevels)).mul(block.timestamp.sub(farmer.lastInteraction));
            return farmer.totalStaked.div(1000000000).mul(level.mul(allLevels)).mul(time);
        }
        else
        {
            return 0;
        }
    }  
}