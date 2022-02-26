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

    address _controller;
    uint256 private _bonusMod;

    // EVENTS //
    event FarmEntered(address sender, uint256 amount, uint8 essenceType);
    event FarmLeft(address sender, uint256 amount, uint8 essenceType);
    event ControllerChanged(address newController);

    // MODIFIERS //
    modifier farmRequired(uint8 farmId) {
        require(farmId <= 4, 'invalid essence farm id');
        _;
    }

    modifier onlyOwner () {
        require(msg.sender == _controller);
        _;
    }

    // CONSTRUCTOR //
    constructor (IERC20 gothPair_)
    {
        // Sets contract owner/controller and the GothPair (GSL token contract)
        _controller = msg.sender;
        _gothPair = gothPair_;
        // Deploys all essence farms and assigns them to the array
        _essenceFarms[0] = new EssenceERC20('Earth Essence', 'EARTH', address(this));
        _essenceFarms[1] = new EssenceERC20('Air Essence', 'AIR', address(this));
        _essenceFarms[2] = new EssenceERC20('Spirit Essence', 'SPIRIT', address(this));
        _essenceFarms[3] = new EssenceERC20('Water Essence', 'WATER', address(this));
        _essenceFarms[4] = new EssenceERC20('Fire Essence', 'FIRE', address(this));
    }

    // VIEW FUNCTIONS //

    // Returns the address of the contract owner/controller
    function controller () external view returns (address)
    {
        return _controller;
    }

    // Returns the bonus modifier value
    function bonusMod () external view returns (uint256)
    {
        return _bonusMod;
    }

    // EXTERNAL FUNCTIONS //

    // Transfers the owner/controller to a new address
    function transferController (address newController) external virtual onlyOwner returns (bool)
    {
        _transferController(newController);
        return true;
    }

    // External call to enter into the specified farm
    function enterFarm (uint256 amount, uint8 farmId) external virtual returns (bool)
    {
        _enterFarm(msg.sender, amount, farmId);
        return true;
    }

    // External call to leave the specified farm
    function leaveFarm (uint256 amount, uint8 farmId) external virtual returns (bool)
    {
        _leaveFarm(msg.sender, amount, farmId);
        return true;
    }

    // External call to claim a users accumulated essence
    function claimEssence (uint8 farmId) external virtual returns (bool)
    {
        _claimEssence(msg.sender, farmId);
        return true;
    }

    // INTERNAL FUNCTIONS //

    // Internal function that has logic to change the owner/controller to the specified address
    function _transferController (address newController) internal virtual
    {
        _controller = newController;
        emit ControllerChanged(newController);
    }

    // Internal function that calculates and sets a users info, total staked GSL tokens across all farms, total essence accumulated across all farms and user bonus
    function _calculateUserInfo (address ofAddress) internal virtual
    {
        User memory user = users[ofAddress];

        user.totalStaked = _getAllFarmTotal(ofAddress);
        user.totalEssence = _getAllEssenceAccumulated(ofAddress);
        user.bonus = _calculateBonus(ofAddress);
    }

    // Internal function that handles entering the specified farm, this is called from the external function enterFarm. 
    // This function checks to see the sender account has the specified GSL token amount then fetches the senders farmer
    // info from the specified farm, it then claims all essence that has been accumlated so far if there is any, transfers 
    // the GSL tokens from the senders account to this contract and increments the users farm amount. 
    function _enterFarm (address sender, uint256 amount, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(_gothPair.balanceOf(sender) >= amount, 'not enough gsl tokens');

        Farmer memory farmer = farmers[farmId][sender];
        _claimEssence(sender, farmId);
        _gothPair.transferFrom(sender, address(this), amount);
        farmer.amount.add(amount);
        emit FarmEntered(sender, amount, farmId);
    }

    // Internal function that handles leaving the specified farm, this is called from the external function leaveFarm.
    // This function checks to see the sender tries to withdraw more than the amount they have in the farm, it then 
    // gets the users farm info, transfers the specified GSL tokens from this contract to the senders account and
    // subtracts the amount from the users farm info.
    function _leaveFarm (address sender, uint256 amount, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(farmers[farmId][sender].amount <= amount, 'attempted to withdraw more than what there is');

        Farmer memory farmer = farmers[farmId][sender];
        _gothPair.transferFrom(address(this), sender, amount);
        farmer.amount.sub(amount);
        emit FarmLeft(sender, amount, farmId);
    }

    // Internal function that handles essence claiming, this is called from multiple functions and requires a valid 
    // farmId to be specified. This function checks to see the the last claim by the sender is less than the current
    // timestamp, this should not happen, at all. The function then gets the users farmer info, calculates the essence
    // amount, mints the essence to the sender and updates the users farm info last claim to the current block timestamp.
    function _claimEssence (address sender, uint8 farmId) internal virtual farmRequired(farmId)
    {
        require(block.timestamp > farmers[farmId][sender].lastClaim, 'claim from the future');

        Farmer memory farmer = farmers[farmId][sender];
        uint256 essence = _calculateEssence(sender, farmer.lastClaim);
     
        _essenceFarms[farmId].mint(sender, essence);

        farmer.lastClaim = block.timestamp;
    }

    // Internal function, calculates the difference between the last claim timestamp and the current block timestamp 
    // and multiplies that by the senders bonus
    function _calculateEssence (address ofAddress, uint256 lastClaim) internal virtual returns (uint256)
    {
        uint256 secondsPast = block.timestamp - lastClaim;
        return secondsPast.mul(_calculateBonus(ofAddress));
    }
    
    // Internal function, needs refactoring with correct algorithm
    function _calculateBonus (address ofAddress) internal virtual returns (uint256)
    {
        /// Needs refactoring
        uint256 bonus = _getAllFarmTotal(ofAddress).div(10000).mul(_bonusMod);
        users[ofAddress].bonus = bonus;
        return bonus;
    }

    // Internal function, gets the total GSL tokens across all of the specified users farms
    function _getAllFarmTotal (address ofAddress) internal virtual returns (uint256)
    {
        uint256 allFarmTotal = 0;
        for (uint8 i = 0; i < 5; i++) {
            allFarmTotal.add(farmers[i][ofAddress].amount);
        }
        return allFarmTotal;
    }

    // Internal function, gets the total essence waiting to be claimed across all of the specified users farms
    function _getAllEssenceAccumulated (address ofAddress) internal virtual returns (uint256)
    {
        uint256 allEssenceAccumulated = 0;
        for (uint8 i = 0; i < 5; i++) {
            allEssenceAccumulated.add(_calculateEssence(ofAddress, farmers[i][ofAddress].lastClaim));
        }
        return allEssenceAccumulated;
    }
}