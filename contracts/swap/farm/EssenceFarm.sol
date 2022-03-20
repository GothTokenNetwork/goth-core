// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./EssenceERC20.sol";
import "./IEssenceFarm.sol";
import "../pairs/IGothPair.sol";
import "../../utils/SafeMath.sol";
import "../../erc20/SafeERC20.sol";
import "../../utils/TransferHelper.sol";
import "../../utils/Ownable.sol";
import "../../utils/Sender.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../IUserLevels.sol";

//    (                                                                   (      \\
//    )\                                                                  )\     \\
//    {_}                                                                 {_}    \\
//   .-;-.  Everything is made  from essence, are you ready to hold the  .-;-.   \\
//  |'-=-'| ingredients  of  creation in  your digital  hands? With the |'-=-'|  \\
//  |     | service  this contract  provides  you  can  enter  GothSwap |     |  \\
//  |     | liquidity tokens into farms and receive  essence in  return.|     |  \\
//  |     | The formulas have  been chosen  to diminish  over time, and |     |  \\
//  |     | thus  with  the  combined  burning  of  the essence  tokens |     |  \\
//  '.___.' through  other  means  will keep  the max  supply in  check.'.___.'  \\

contract EssenceFarm is IEssenceFarm, Ownable, Sender, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for EssenceERC20;

// Define Structs
    struct Effect { 
        uint32 value; 
        uint32 expires; 
        bytes32 potionId;  
    }

    struct FarmInfo { 
        uint256 staked; 
        uint256 accruedEssence; 
        uint32 lastInteraction; 
        Effect bonusYield;
        Effect farmMorph;
    } 

    struct Farm { EssenceERC20 essence; IGothPair pair; uint32 farmBonus; }

// Arrays & Mappings
    mapping(uint256 => mapping(address => FarmInfo)) _farmers;
    Farm[] private _farms;

// Paramaters
    IUserLevels private _userLevels;
    address private _potionMaster;
    uint256 private _baseMintRate;

// Events
    event Deposit(address sender, uint256 amount, uint256 farmId);
    event Withdraw(address sender, uint256 amount, uint256 farmId);
    event ClaimReward(address sender, uint256 amount, uint256 farmId);
    event AddFarm(string name, string symbol, uint256 bonus, address pairAddress, uint256 farmId);
    event SetPotionMaster(address newPotionMaster);
    event InstantEssencePayout(uint256 farmId, uint256 amount, address user);
    event ApplyBonusYield(uint256 farmId, uint32 bonus, uint32 expires, bytes32 potionId, address user);
    event ApplyFarmMorph(uint256 farmId, uint32 morphTo, uint32 expires, bytes32 potionId, address user);
    event SetUserLevels(address newUserLevels);
    event PotionEffectExpired(address user, bytes32 potionId);

// Modifiers
    modifier farmRequired(uint256 farmId) {
        require(farmId <= _farms.length - 1, 'farmRequired: invalid farm id');
        _;
    }

    modifier onlyPotionMaster() {
        require(_potionMaster == _msgSender(), "onlyPotionMaster: caller is not the potion master");
        _;
    }

// Constructor
    constructor (IGothPair gothPair_)
    {
        _baseMintRate = 1e18;
        addFarm("Earth Essence", "EARTH", 1, gothPair_);
        addFarm("Air Essence", "AIR", 1, gothPair_);
        addFarm("Spirit Essence", "SPIRIT", 1, gothPair_);
        addFarm("Water Essence", "WATER", 1, gothPair_);
        addFarm("Fire Essence", "FIRE", 1, gothPair_);
    }

// Paramater Management
    function setUserLevels (IUserLevels newUserLevels) external onlyOwner {
        _userLevels = newUserLevels;
        emit SetUserLevels(address(_userLevels));
    }

    function userLevels () external view override returns (address) {
        return address(_userLevels);
    }

    function setPotionMaster (address newPotionMaster) external onlyOwner {
        _potionMaster = newPotionMaster;
        emit SetPotionMaster(_potionMaster);
    }

    function potionMaster () external view override returns (address) {
        return _potionMaster;
    }

// Farm Management
    function farmAddress (uint256 farmId) external view override returns (address) {
        require(farmId <= _farms.length - 1, 'invalid farm id');
        return address(_farms[farmId].essence);
    }

    function farmerInfo (uint256 farmId) external view override returns (uint256[3] memory) {
        require(farmId <= _farms.length - 1, 'invalid farm id');
        FarmInfo memory farmInfo = _farmers[farmId][msg.sender];
        uint256[3] memory info = [farmInfo.staked, farmInfo.accruedEssence, farmInfo.lastInteraction];
        return info;
    }  

    function farmCount () external view override returns (uint256) {
        return _farms.length;
    }

    function farmBalance (uint256 farmId) public view farmRequired(farmId) returns (uint256) {
        require(farmId <= _farms.length - 1, 'invalid farm id');
        return _farms[farmId].pair.balanceOf(address(_farms[farmId].essence));
    }

    function farmBalanceOf (uint256 farmId, address sender) public view farmRequired(farmId) returns (uint256) {
        return _farms[farmId].essence.balanceOf(sender);
    }

    function addFarm (string memory name, string memory symbol, uint32 bonus, IGothPair pair) public onlyOwner {
        require(bytes(name).length > 0, "addFarm: please provide name");
        require(bytes(symbol).length > 0, "addFarm: please provide symbol");
        require(bonus > 0, "addFarm: bonus cannot be 0");
        _farms.push(
            Farm({
                essence: new EssenceERC20(name, symbol, pair),
                pair: pair,
                farmBonus: bonus
            })
        );
        emit AddFarm(name, symbol, bonus, address(pair), _farms.length - 1);
    }

// Farm Interaction
    function deposit (uint256 amount, uint256 farmId) external farmRequired(farmId) nonReentrant returns (bool)
    {
        require(_farms[farmId].pair.balanceOf(msg.sender) >= amount, "deposit: not enough GSL tokens");   
        require(_farms[farmId].pair.allowance(msg.sender, address(this)) >= amount, "deposit: GSL tokens have not been approved for transfer by the sender");

        FarmInfo storage farmer = _farmers[farmId][msg.sender];
        
        if (farmer.staked == 0)
        {
            _userLevels.initializeUser(msg.sender);
        }
        
        if (farmer.staked > 0)
        {
            farmer.accruedEssence = calculateRewardSinceLastTimestamp(msg.sender, farmId);
        }

        farmer.staked = farmer.staked + amount;
        farmer.lastInteraction = uint32(block.timestamp);
        TransferHelper.safeTransferFrom(address(_farms[farmId].pair), msg.sender, address(_farms[farmId].essence), amount);
        emit Deposit(msg.sender, amount, farmId);
        return true;
    }

    function withdraw (uint256 amount, uint256 farmId) external farmRequired(farmId) nonReentrant returns (bool)
    {
        FarmInfo storage farmer = _farmers[farmId][msg.sender];
        require(farmer.staked >= amount, "withdraw: sender does not have that many GSL tokens staked in this farm");

        if (farmer.staked == amount)
        {
            claimReward(msg.sender, farmId);
        }
        else
        {
            farmer.accruedEssence = farmer.accruedEssence + calculateRewardSinceLastTimestamp(msg.sender, farmId);
        }

        farmer.staked = farmer.staked - amount;
        farmer.lastInteraction = uint32(block.timestamp);
        _farms[farmId].essence.withdrawGSLTo(msg.sender, amount);
        emit Withdraw(msg.sender, amount, farmId);
        return true;
    }
    
// Reward Management
    function claimReward (address sender, uint256 farmId) public farmRequired(farmId)
    {
        FarmInfo memory farmer = _farmers[farmId][sender];
        require(farmer.staked > 0, "claimReward: no GSL staked");
        uint256 reward = farmer.accruedEssence + calculateRewardSinceLastTimestamp(sender, farmId);
        farmer.accruedEssence = 0;
        uint256 farmToMint = farmId;

        if (farmer.farmMorph.expires > block.timestamp)
        {
            farmToMint = farmer.farmMorph.value;
        }
        else
        {
            if (farmer.farmMorph.potionId.length > 0)
            {
                emit PotionEffectExpired(sender, farmer.farmMorph.potionId);
                farmer.farmMorph.potionId = "";
            }  
        }

        _userLevels.incrementExperience(sender, reward);
        _farms[farmToMint].essence.mint(sender, reward);
        emit ClaimReward(sender, reward, farmId);
    }

    function calculateReward (uint256 farmId) external view farmRequired(farmId) returns (uint256)
    {
        return _farmers[farmId][msg.sender].accruedEssence + calculateRewardSinceLastTimestamp(msg.sender, farmId);
    }

    function calculateRewardSinceLastTimestamp (address sender, uint256 farmId) private view farmRequired(farmId) returns (uint256)
    {
        FarmInfo storage farmer = _farmers[farmId][sender];
        if (farmer.staked > 0)
        {
            uint256 time = block.timestamp.sub(farmer.lastInteraction);
            uint32 bonusYield = 0;

            uint256 totalUserLevel = _userLevels.totalUserLevels();
            uint256 userLevel = _userLevels.levelOf(sender);

            if (farmer.bonusYield.value > 1 && farmer.bonusYield.expires < block.timestamp)
            {
                bonusYield = uint32(farmer.bonusYield.value);
            }
            else
            {
                farmer.bonusYield.value = 1;

                if (farmer.bonusYield.potionId.length > 0)
                {
                    emit PotionEffectExpired(sender, farmer.bonusYield.potionId);
                    farmer.bonusYield.potionId = "";
                }
            }

            uint256 share = farmer.staked.mul(1e12).div(farmBalance(farmId)).mul(100);
            uint256 mintShare = share.div(_baseMintRate).mul(100).mul(time);
            uint levelBonus = userLevel.add(share.div(10));
            // (((Share/Minted*100)*Time))+(Level+(Share/10))*(Bonus)
            uint256 reward = mintShare.add(levelBonus).mul(bonusYield);

            return reward;
        }
        else
        {
            return 0;
        }
    }

// Potion Effect Management
    function instantEssencePayout (uint256 farmId, uint256 amount, address farmUser) public onlyPotionMaster farmRequired (farmId)
    {
        _farms[farmId].essence.mint(farmUser, amount);
        emit InstantEssencePayout(farmId, amount, farmUser);
    }

    function applyBonusYield (uint256 farmId, uint32 bonus, uint32 expires, bytes32 potionId, address farmUser) public onlyPotionMaster farmRequired (farmId)
    {
        require(bonus > 0, "applyBonusYield: bonus cannot be 0");
        FarmInfo storage farmer = _farmers[farmId][farmUser];
        farmer.bonusYield.value = bonus;
        farmer.bonusYield.expires = expires;
        farmer.bonusYield.potionId = potionId;
        emit ApplyBonusYield(farmId, bonus, expires, potionId, farmUser);
    }

    function applyFarmMorph (uint256 farmId, uint32 morphTo, uint32 expires, bytes32 potionId, address farmUser) public onlyPotionMaster farmRequired (farmId)
    {
        require(morphTo <= _farms.length - 1, 'applyFarmMorph: invalid farm id to morph to');
        FarmInfo storage farmer = _farmers[farmId][farmUser];
        farmer.farmMorph.value = morphTo;
        farmer.farmMorph.expires = expires;
        farmer.farmMorph.potionId = potionId;
        emit ApplyFarmMorph(farmId, morphTo, expires, potionId, farmUser);
    }
}