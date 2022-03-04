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
    EssenceERC20[] private _essenceFarms;
    // Earth Essence = 0
    // Air Essence = 1
    // Spirit Essence = 2
    // Water Essence = 3
    // Fire Essence = 4

    // GothPair interface
    IERC20[] private _acceptedPairs;

    // Potion Manager
    address private _potionManager;

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
    uint256 private _baseMintRate;

    // EVENTS //
    event Deposit(address sender, uint256 amount, uint8 farmId);
    event Withdraw(address sender, uint256 amount, uint8 farmId);
    event EssenceClaimed(address sender, uint256 amount, uint8 farmId);
    event AddFarm(string name, string symbol, uint256 farmId);
    event RemoveFarm(string message, uint256 farmId);
    event SetBaseMintRate(uint256 newMintRate);
    event CalculateTest(uint256 levelMod, uint256 reward, uint256 multiplier);
    event IncrementExperience(address sender, uint256 experience, uint256 level);

    // MODIFIERS //
    modifier farmRequired(uint8 farmId) {
        require(farmId <= _essenceFarms.length - 1, 'invalid essence farm id');
        _;
    }

      ///////////////////////////////////////////////
     // UPDATE CONTRACT TO SUPPORT MULTIPLE POOLS //
    ///////////////////////////////////////////////

    // CONSTRUCTOR //
    constructor (IERC20 gothPair_)
    {
        _acceptedPairs.push(gothPair_);
        _baseMintRate = 10000000000000000000;
        // Deploys all essence farms and assigns them to the array
        addFarm('Earth Essence', 'EARTH');
        addFarm('Air Essence', 'AIR');
        addFarm('Spirit Essence', 'SPIRIT');
        addFarm('Water Essence', 'WATER');
        addFarm('Fire Essence', 'FIRE');
    }

    function gothPair () external view returns (address) { 
        return address(_gothPair); 
    }

    // Adds a new farm to the _essenceFarm array, will not function if parameters are empty 
    function addFarm (string memory name, string memory symbol) public onlyOwner {
        require(bytes(name).length > 0, "addFarm: please provide name");
        require(bytes(symbol).length > 0, "addFarm: please provide symbol");
        _essenceFarms.push(new EssenceERC20(name, symbol, _gothPair));
        emit AddFarm(name, symbol, _essenceFarms.length - 1);
    }

    // It is impossible for a farm to be removed if there is any GSL at the farm contract address.
    // All GSL must be claimed, returned or otherwise moved for the farm to be removed, farmer info will
    // still contain all the staker info for their position within the farm and if needed be used to 
    // refund stakers who didn't reclaim their tokens, but from a different address. Essence farm tokens 
    // are ERC20 compliant and can be handled normally even if the farm is removed. The original 5 
    // Essence farms cannot be removed, they are protected. This requires a valid farm ID
    function removeFarm (uint8 farmId) public onlyOwner farmRequired(farmId) returns (bool)
    {
        require(farmId > 4, "removeFarm: protected farm");
        require(_gothPair.balanceOf(address(_essenceFarms[farmId])) <= 0, "removeFarm: farm still has GSL tokens staked");
        delete _essenceFarms[farmId];
        emit RemoveFarm("Essence farm has been removed", farmId);
    }

    // Retrieves the total GSL staked by the sener in the farm specified, this requires a valid farm ID
    function farmTotalStaked (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].totalStaked; 
    }

    // Retrieves the last interaction timestamp of the sender, this requires a valid farm ID
    function farmlastInteraction (uint8 farmId) external view farmRequired(farmId) returns (uint256) { 
        return farmers[farmId][msg.sender].lastInteraction; 
    }

    // Retrieves the address of the farm specified, this requires a valid farm ID
    function essenceFarm (uint8 farmId) public view farmRequired(farmId) returns (address) {
        return address(_essenceFarms[farmId]);
    }

    // Retrieves the total number of farms
    function farmCount () public view returns (uint256) {
        return _essenceFarms.length;
    }

    // Sets the base mint rate of essence
    function setBaseMintRate (uint256 newMintRate) public onlyOwner {
        _baseMintRate = newMintRate;
        emit SetBaseMintRate(_baseMintRate);
    }

    // Retrieves the base mint rate of essence
    function baseMintRate () external view returns (uint256) {
        return _baseMintRate;
    }

    // Retrieves the total GSL staked in the farm contract address, this requires a valid farm ID
    function gslFarmBalance (uint8 farmId) public view farmRequired(farmId) returns (uint256) {
        return _gothPair.balanceOf(address(_essenceFarms[farmId]));
    }

    // Retrieves the user info of the sender
    function userInfo () external view returns (uint256[3] memory) {
        User memory user = users[msg.sender];
        uint256[3] memory info = [user.experience, user.level, user.nextUnlock];
        return info;
    }   

    // Retrieves the farmer info by the sender of the farm specified, this requires a valid farm ID
    function farmInfo (uint8 farmId) external view farmRequired(farmId) returns (uint256[3] memory) {
        Farmer memory farm = farmers[farmId][msg.sender];
        uint256[3] memory info = [farm.totalStaked, farm.accruedEssence, farm.lastInteraction];
        return info;
    }  

    function actualFarmBalance (uint8 farmId) external view farmRequired(farmId) returns (uint256) {
        return _essenceFarms[farmId].balanceOf(msg.sender);
    } 

    // Deposits the amount within the specified farm, this requires a valid farm ID. The function
    // requires the sender to have enough GSL tokens at their address and then requires this contract
    // to be approved for spending those tokens. The senders farmer info is then pulled from the 
    // mapping using the farm ID specified and the senders address. The total accrued essence is
    // calculated since the last interaction timestamp, if the sender already has GSL within
    // the farm then the farmer info accruedEssence is updated with the latest calculation, the 
    // farmer info totalStaked is incremented with the new amount, the last interaction timestamp
    // is updated to the current blocks timestamp and finally we use a safe transfer from to move 
    // the GSL from the senders address to the farm.
    function deposit (uint256 amount, uint8 farmId) public farmRequired(farmId)
    {
        require(_gothPair.balanceOf(msg.sender) >= amount, "deposit: not enough GSL tokens");   
        require(_gothPair.allowance(msg.sender, address(this)) >= amount, "deposit: GSL tokens have not been approved for transfer by the sender");

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

    // Withdraws the requested amount from the farm by the sender. Retreives the farmer info using farm
    // ID and sender address. Requires the amount requested to be lower of equal to the total GSL they
    // have within the farm. If the amount requested is all of their GSL in the farm it claims all the
    // essence accrued up until that point to the sender, if the amount requested is less than the senders
    // total GSL within the farm, the essence that is accrued between the last interaction timestamp and
    // the current block timestamp is calculated and farmer info accruedEssence is updated. The amount is
    // then subtracted from farmer info totalStaked, farmer info lastInteraction is updated with the
    // current block timestamp and finally, the function withdraws the GSL from the farm and transfers it to
    // sender, be aware the actual transfer to the sender is called on the farm contract
    function withdraw (uint256 amount, uint8 farmId) public farmRequired(farmId)
    {
        Farmer storage farmer = farmers[farmId][msg.sender];
        require(farmer.totalStaked >= amount, "withdraw: sender does not have that many GSL tokens staked in this farm");

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

    // Claims the total essence accrued between the last two lastInteraction timestamps and then the 
    // recently accrued essence between the most recent lastInteraction timestamp and the current block
    // timestamp. It then mints the essence reward to the senders address. 
    function claimEssence (address sender, uint8 farmId) public farmRequired(farmId)
    {
        Farmer storage farmer = farmers[farmId][sender];
        require(farmer.totalStaked > 0, "claimEssence: sender does not have any GSL tokens staked");

        uint256 reward = farmer.accruedEssence + calculateEssenceSincelastInteraction(sender, farmId);
        incrementExperience(sender, reward);

        farmer.accruedEssence = 0;
        farmer.lastInteraction = block.timestamp;
        _essenceFarms[farmId].mint(sender, reward);
        emit EssenceClaimed(msg.sender, reward, farmId);
    }

    // Calculates the essence reward of the sender between the lastInteraction timestamp and the current
    // block timestamp. The time in seconds is calculated between the current block timestamp and the 
    // lastInteraction timestamp, the resulting time is then multiplied by the base mint rate and then
    // multiplied again by the senders GSL tokens that are in the farm, this is divided by the total
    // GSL in the farm, which is further divided by the result of subtracting the senders farmer level
    // from the overall total level of all the users of the farm.
    function calculateEssenceSincelastInteraction (address sender, uint8 farmId) private farmRequired(farmId) returns (uint256)
    {
        Farmer storage farmer = farmers[farmId][sender];
        if (farmer.lastInteraction < block.timestamp && farmer.totalStaked > 0)
        {
            uint256 multiplier = block.timestamp.sub(farmer.lastInteraction);
            uint256 levelMod = _totalUserLevels.sub(users[sender].level) > 0 ? _totalUserLevels.sub(users[sender].level) : 1;

            uint256 reward = multiplier
                .mul(_baseMintRate)
                .mul(farmer.totalStaked)
                .div(gslFarmBalance(farmId))
                .div(levelMod);

            emit CalculateTest(levelMod, reward, multiplier);
            return reward;
        }
        else
        {
            return 0;
        }
    }  

    function incrementExperience (address sender, uint256 reward) internal
    {
        User storage user = users[sender];
        uint256 exp = reward.div(1e12);
        user.experience = user.experience.add(exp);
        calculateLevel();
        emit IncrementExperience(sender, exp, user.level);
    } 

    function calculateLevel () internal
    {
        User storage user = users[msg.sender];
        uint256 mod = 625;
        uint256 base = 25;
        user.level = base.mul(4).add(sqrt(mod.mul(100).mul(user.experience))).div(50);
        user.nextUnlock = base.mul(user.level).mul(user.level).sub(base.mul(user.level));
    }

    function sqrt(uint y) internal pure returns (uint z) 
    {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}