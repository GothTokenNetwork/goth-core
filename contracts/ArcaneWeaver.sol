// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./utils/SafeMath.sol";
import "./utils/EnumerableSet.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/BoringOwnable.sol";
import "./erc20/BoringERC20.sol";
import "./court/ArcaneSigils.sol";
import "./interfaces/IArcaneDispenser.sol";

contract ArcaneWeaver is BoringOwnable, ReentrancyGuard
{
    // USINGS //
    using SafeMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for ArcaneSigils;
    using EnumerableSet for EnumerableSet.AddressSet;

    // STRUCTS //
    struct Weaver {
        uint256 amount;
        uint256 accrued;
    }

    struct ArcaneFarm {
        IERC20 lpToken;
        uint256 accSigilPerShare;
        uint256 lastRewardTime;
        uint256 allocationPoints;
        IArcaneDispenser dispenser;
    }

    // STATE VARIABLES //
    ArcaneSigils public sigil;
    ArcaneFarm[] public arcaneFarms;
    EnumerableSet.AddressSet private lpTokens;
    mapping(uint256 => mapping(address => Weaver)) public weavers;
    uint256 public totalAllocationPoints;
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;

    address public devAddr;
    address public treasuryAddr;
    address public investorAddr;
    uint256 public sigilPerSec;
    uint256 public devPercent;
    uint256 public treasuryPercent;
    uint256 public investorPercent; 

    uint256 public startTimestamp;

    // EVENTS //
    event FarmAdd(uint256 indexed farmId, uint256 allocation, IERC20 indexed lpToken, IArcaneDispenser indexed dispenser);
    event SetFarm(uint256 indexed farmId, uint256 allocation, IArcaneDispenser indexed dispenser, bool overwrite);
    event UpdatePool(uint256 indexed farmId, uint256 lastRewardTime, uint256 lpSupply, uint256 accSigilPerShare);
    event Collection(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event Deposit(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event Withdraw(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event EmergencyWithdraw(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event UpdateEmissionRate(address indexed account, uint256 _sigilPerSec);

    constructor
    (ArcaneSigils _sigil, address _devAddr, address _treasuryAddr, address _investorAddr, uint256 _sigilPerSec, 
    uint256 _startTime, uint256 _devPercent, uint256 _treasuryPercent, uint256 _investorPercent)
    {
        require(0 <= _devPercent && _devPercent <= 1000, "constructor: invalid dev percent value");
        require(0 <= _treasuryPercent && _treasuryPercent <= 1000, "constructor: invalid treasury percent value");
        require(0 <= _investorPercent && _investorPercent <= 1000, "constructor: invalid investor percent value");
        require(_devPercent + _treasuryPercent + _investorPercent <= 1000, "constructor: total percent over max");

        sigil = _sigil;
        devAddr = _devAddr;
        treasuryAddr = _treasuryAddr;
        investorAddr = _investorAddr;
        sigilPerSec = _sigilPerSec;
        startTimestamp = _startTime;
        devPercent = _devPercent;
        treasuryPercent = _treasuryPercent;
        investorPercent = _investorPercent;
        totalAllocationPoints = 0;
    }

    function farmLength () external view returns (uint256 farms)
    {
        farms = arcaneFarms.length;
    }

    function addFarm (uint256 allocation, IERC20 lpToken, IArcaneDispenser dispenser) external onlyOwner
    {
        require(!lpTokens.contains(address(lpToken)), "addFarm: farm has already been added.");
        lpToken.balanceOf(address(this));

        if (address(dispenser) != address(0)) 
        {
            dispenser.onSigilReward(address(0), 0);
        }

        uint256 lastRewardTime = block.timestamp;
        totalAllocationPoints = totalAllocationPoints.add(allocation);

        arcaneFarms.push(
            ArcaneFarm(
                {
                    lpToken: lpToken,
                    allocationPoints: allocation,
                    lastRewardTime: lastRewardTime,
                    accSigilPerShare: 0,
                    dispenser: dispenser
                }
            )
        );

        lpTokens.add(address(lpToken));
        emit FarmAdd(arcaneFarms.length.sub(1), allocation, lpToken, dispenser);
    }

    function setFarm (uint256 farmId, uint256 allocation, IArcaneDispenser dispenser, bool overwrite) external onlyOwner
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        totalAllocationPoints = totalAllocationPoints.sub(arcaneFarms[farmId].allocationPoints).add(allocation);
        farm.allocationPoints = allocation;

        if (overwrite)
        {
            dispenser.onSigilReward(address(0), 0);
            farm.dispenser = dispenser;
        }

        arcaneFarms[farmId] = farm;
        emit SetFarm(farmId, allocation, overwrite ? dispenser : farm.dispenser, overwrite);
    }

    function pendingTokens (uint256 farmId, address weaverAddress) external view 
    returns (uint256 pendingSigil, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken)
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][weaverAddress];
        uint256 accSigilPerShare = farm.accSigilPerShare;
        uint256 lpSupply = farm.lpToken.balanceOf(address(this));

        if (block.timestamp > farm.lastRewardTime && lpSupply != 0)
        {
            uint256 secondsElapsed = block.timestamp.sub(farm.lastRewardTime);
            uint256 sigilReward = secondsElapsed.mul(sigilPerSec).mul(farm.allocationPoints).div(totalAllocationPoints);
            accSigilPerShare = accSigilPerShare.add(sigilReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }

        pendingSigil = weaver.amount.mul(accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);

        if (address(farm.dispenser) != address(0))
        {
            bonusTokenAddress = address(farm.dispenser.rewardToken());
            bonusTokenSymbol = IERC20(farm.dispenser.rewardToken()).safeSymbol();
            pendingBonusToken = farm.dispenser.pendingTokens(weaverAddress);
        }
    }

    function massUpdateFarms (uint256[] memory farmIds) public
    {
        uint256 length = farmIds.length;
        for (uint256 i = 0; i < length; ++i)
        {
            updateFarm(farmIds[i]);
        }
    }

    function updateFarm (uint256 farmId) public 
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        if (block.timestamp > farm.lastRewardTime)
        {
            uint256 lpSupply = farm.lpToken.balanceOf(address(this));
            if (lpSupply > 0)
            {
                uint256 secondsElapsed = block.timestamp.sub(farm.lastRewardTime);
                uint256 sigilReward = secondsElapsed.mul(sigilPerSec).mul(farm.allocationPoints).div(totalAllocationPoints);

                uint256 lpPercent = 1000 - devPercent - treasuryPercent - investorPercent;
                sigil.mint(devAddr, sigilReward.mul(devPercent).div(1000));
                sigil.mint(treasuryAddr, sigilReward.mul(treasuryPercent).div(1000));
                sigil.mint(investorAddr, sigilReward.mul(investorPercent).div(1000));
                sigil.mint(address(this), sigilReward.mul(lpPercent).div(1000));

                farm.accSigilPerShare = farm.accSigilPerShare.add((sigilReward.mul(ACC_TOKEN_PRECISION).div(lpSupply)));               
            }
            farm.lastRewardTime = block.timestamp;
            arcaneFarms[farmId] = farm;
            emit UpdatePool(farmId, farm.lastRewardTime, lpSupply, farm.accSigilPerShare);
        }
    }

    function deposit (uint256 farmId, uint256 amount) external nonReentrant
    {
        updateFarm(farmId);

        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];

        if (weaver.amount > 0)
        {
            uint256 pending = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);
            sigil.safeTransfer(msg.sender, pending);
            emit Collection(msg.sender, farmId, pending);
        }

        uint256 balanceBefore = farm.lpToken.balanceOf(address(this));
        farm.lpToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountReceived = farm.lpToken.balanceOf(address(this)).sub(balanceBefore);

        weaver.amount = weaver.amount.add(amountReceived);
        weaver.accrued = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION);

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0))
        {
            dispenser.onSigilReward(msg.sender, weaver.amount);
        }

        emit Deposit(msg.sender, farmId, amountReceived);
    }

    function withdraw (uint256 farmId, uint256 amount) external nonReentrant
    {
        updateFarm(farmId);
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];

        if (weaver.amount > 0)
        {
            uint256 pending = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);
            sigil.safeTransfer(msg.sender, pending);
            emit Collection(msg.sender, farmId, pending);
        }

        weaver.amount = weaver.amount.sub(amount);
        weaver.accrued = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION);

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0))
        {
            dispenser.onSigilReward(msg.sender, weaver.amount);
        }

        farm.lpToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, farmId, amount);
    }

    function emergencyWithdraw(uint256 farmId) external nonReentrant {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];
        uint256 amount = weaver.amount;
        weaver.amount = 0;
        weaver.accrued = 0;

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0)) {
            dispenser.onSigilReward(msg.sender, 0);
        }

        farm.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, farmId, amount);
    }

    // function updateEmissionRate(uint256 _sigilPerSec) public onlyOwner 
    // {
    //     uint256 length = arcaneFarms.length - 1;
    //     uint256[length] memory ids;
    //     for (uint256 i = 0; i < arcaneFarms.length; ++i)
    //     {
    //         ids[i] = i;
    //     } 
    //     massUpdateFarms(ids);
    //     sigilPerSec = _sigilPerSec;
    //     emit UpdateEmissionRate(msg.sender, _sigilPerSec);
    // }
}