// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/SafeMath.sol";
import "../utils/Address.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/BoringOwnable.sol";
import "../erc20/SafeERC20.sol";
import "../interfaces/IArcaneWeaver.sol";
import "../interfaces/IArcaneDispenser.sol";

// This is a forked and modified version of the SimpleRewarderPerSec contract from Trader Joe's joe-core respository found here
// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/rewarders/SimpleRewarderPerSec.sol

contract BasicDispenserPerSec is IArcaneDispenser, BoringOwnable, ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Weaver {
        uint256 amount;
        uint256 accrued;
        uint256 unpaid;
    }

    struct ArcaneFarm {
        uint256 accTokenPerShare;
        uint256 lastRewardTime;
    }

    IERC20 public immutable override rewardToken;
    IERC20 public immutable lpToken;
    bool public immutable isNative;
    IArcaneWeaver public immutable ARCANE_WEAVER;
    uint256 public tokenPerSec;

    uint256 private constant ACC_TOKEN_PRECISION = 1e36;

    ArcaneFarm Farm;
    mapping(address => Weaver) public Weavers;

    event OnReward (address indexed weaver, uint256 amount);
    event RewardRateUpdate(uint256 oldRate, uint256 newRate);

    modifier onlyArcaneWeaver() 
    {
        require(msg.sender == address(ARCANE_WEAVER), "onlyArcaneWeaver: Only ArcaneWeaver contract can call this function");
        _;
    }

    constructor (IERC20 _rewardToken, IERC20 _lpToken, uint256 _tokenPerSec, IArcaneWeaver _ARCANE_WEAVER, bool _isNative)
    {
        require(Address.isContract(address(_rewardToken)), "constructor: reward token must be a valid contract");
        require(Address.isContract(address(_lpToken)), "constructor: LP token must be a valid contract");
        require(Address.isContract(address(_ARCANE_WEAVER)), "constructor: ArcaneWeaver must be a valid contract");
        require(_tokenPerSec <= 1e30, "constructor: token per seconds can't be greater than 1e30");

        rewardToken = _rewardToken;
        lpToken = _lpToken;
        tokenPerSec = _tokenPerSec;
        ARCANE_WEAVER = _ARCANE_WEAVER;
        isNative = _isNative;
        Farm = ArcaneFarm({lastRewardTime: block.timestamp, accTokenPerShare: 0});
    }

    receive() external payable {}

    function onSigilReward (address weaverAddress, uint lpAmount) external override onlyArcaneWeaver nonReentrant
    {
        updateFarm();
        ArcaneFarm memory farm = Farm;
        Weaver storage weaver = Weavers[weaverAddress];

        uint256 pending;

        if (weaver.amount > 0) 
        {
            pending = (weaver.amount.mul(farm.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(weaver.accrued).add(
                weaver.unpaid
            );

            if (isNative) 
            {
                uint256 balance = address(this).balance;
                if (pending > balance) 
                {
                    (bool success, ) = weaverAddress.call{value:balance}("");
                    require(success, "Transfer failed");
                    weaver.unpaid = pending - balance;
                } 
                else 
                {
                    (bool success, ) = weaverAddress.call{value:pending}("");
                    require(success, "Transfer failed");
                    weaver.unpaid = 0;
                }
            } 
            else 
            {
                uint256 balance = rewardToken.balanceOf(address(this));
                if (pending > balance) 
                {
                    rewardToken.safeTransfer(weaverAddress, balance);
                    weaver.unpaid = pending - balance;
                } 
                else 
                {
                    rewardToken.safeTransfer(weaverAddress, pending);
                    weaver.unpaid = 0;
                }
            }
        }

        weaver.amount = lpAmount;
        weaver.accrued = weaver.amount.mul(farm.accTokenPerShare) / ACC_TOKEN_PRECISION;
        emit OnReward(weaverAddress, pending - weaver.unpaid); 
    }

    function pendingTokens(address weaverAddress) external view override returns (uint256 pending) 
    {
        ArcaneFarm memory farm = Farm;
        Weaver storage weaver = Weavers[weaverAddress];

        uint256 accTokenPerShare = farm.accTokenPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(ARCANE_WEAVER));

        if (block.timestamp > farm.lastRewardTime && lpSupply != 0) 
        {
            uint256 timeElapsed = block.timestamp.sub(farm.lastRewardTime);
            uint256 tokenReward = timeElapsed.mul(tokenPerSec);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }

        pending = (weaver.amount.mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(weaver.accrued).add(
            weaver.unpaid
        );
    }

    function rewardTokenBalance() external view returns (uint256) 
    {
        if (isNative) 
        {
            return address(this).balance;
        } 
        else 
        {
            return rewardToken.balanceOf(address(this));
        }
    }

    function setRewardRate(uint256 _tokenPerSec) external onlyOwner 
    {
        updateFarm();

        uint256 oldRate = tokenPerSec;
        tokenPerSec = _tokenPerSec;

        emit RewardRateUpdate(oldRate, _tokenPerSec);
    }

    function updateFarm() public returns (ArcaneFarm memory farm) 
    {
        farm = Farm;

        if (block.timestamp > farm.lastRewardTime) 
        {
            uint256 lpSupply = lpToken.balanceOf(address(ARCANE_WEAVER));

            if (lpSupply > 0) 
            {
                uint256 timeElapsed = block.timestamp.sub(farm.lastRewardTime);
                uint256 tokenReward = timeElapsed.mul(tokenPerSec);
                farm.accTokenPerShare = farm.accTokenPerShare.add((tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply));
            }

            farm.lastRewardTime = block.timestamp;
            Farm = farm;
        }
    }

    function emergencyWithdraw() public onlyOwner 
    {
        if (isNative)
        {
            (bool success, ) = msg.sender.call{value:address(this).balance}("");
            require(success, "Transfer failed");
        } 
        else 
        {
            rewardToken.safeTransfer(address(msg.sender), rewardToken.balanceOf(address(this)));
        }
    }
}