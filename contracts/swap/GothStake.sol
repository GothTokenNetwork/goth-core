// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../erc20/ERC20.sol";
import "../utils/SafeMath.sol";
import "../utils/Ownable.sol";
import "../utils/ReentrancyGuard.sol";
import "./GothTokenV2.sol";

contract GothStake is ERC20("GOTH Bits", "bGOTH"), Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    GothTokenV2 public goth;

    uint256 public enterFeeMod; // (amount * 1e18) / enterFeeMod = Actual Fee
    uint256 public leaveFee; // Static

    uint256 public mintRate; // 0-15

    uint256 public treasuryPercent; // Default - 100
    address public treasuryAddress;
    uint256 public teamPercent; // Default - 100
    address public teamAddress;

    address public feeAddress;

    mapping(address => uint256) public lastClaimTime;
    uint256 public totalStaked;

    event ChangeGothOwner (address newOwner);
    event SetEnterFeeMod (uint256 newFeeMod);
    event SetLeaveFee (uint256 newLeavefee);
    event SetMintRate (uint256 newMintRate);
    event SetTreasuryAddress (address newAddress);
    event SetTeamAddress (address newAddress);
    event SetFeeAddress (address feeAddress);
    event Enter (address indexed account, uint256 share);
    event Leave (address indexed account, uint256 share);
    event Gather (address indexed account, uint256 amount);

    constructor (GothTokenV2 _goth)
    {
        goth = _goth;
        enterFeeMod = 2.5e8;
        leaveFee = 1.5e16;
        mintRate = 10;
        treasuryPercent = 100;
        teamPercent = 100;
        treasuryAddress = 0xDCb9C36998703ae5CEE2ec07Bef76e61A571906D;
        teamAddress = 0x8A1eA60Fe793FE009078A74d6167a8EeaD25f7F1;
        feeAddress = 0xbD2171Ea845D383e731ab29eDbCDd6f121305be3;
    }

    function changeGothOwner (address newOwner) public onlyOwner
    {
        require(newOwner != address(0) || newOwner != address(1), "changeGothOwner: cannot be zero addresses");
        goth.transferOwnership(newOwner);
        emit ChangeGothOwner(newOwner);
    }

    function setEnterFeeMod (uint256 newFeeMod) public onlyOwner
    {
        require(newFeeMod <= 1e13 && newFeeMod >= 1e8, "setEnterFeeMod: enter fee mod too high");
        enterFeeMod = newFeeMod;
        emit SetEnterFeeMod(newFeeMod);
    }

    function setLeaveFee (uint256 newLeaveFee) public onlyOwner
    {
        require(newLeaveFee <= 1e17, "setLeaveFee: leave fee too high");
        leaveFee = newLeaveFee;
        emit SetLeaveFee(newLeaveFee);
    }

    function setTreasuryAddress (address newTreasury) public onlyOwner
    {
        require(newTreasury != address(0) || newTreasury != address(1), "setTreasuryAddress: cannot be zero addresses");
        treasuryAddress = newTreasury;
        emit SetTreasuryAddress(newTreasury);
    }

    function setTeamAddress (address newTeam) public onlyOwner
    {
        require(newTeam != address(0) || newTeam != address(1), "setTeamAddress: cannot be zero addresses");
        teamAddress = newTeam;
        emit SetTreasuryAddress(newTeam);
    }

    function setFeeAddress (address newFeeAddress) public onlyOwner
    {
        require(newFeeAddress != address(0) || newFeeAddress != address(1), "setFeeAddress: cannot be zero addresses");
        feeAddress = newFeeAddress;
        emit SetFeeAddress(newFeeAddress);
    }

    function setMintRate (uint256 newMintRate) public onlyOwner
    {
        require(newMintRate <= 15, "setMintRate: mint rate too high");
        mintRate = newMintRate;
        emit SetMintRate(newMintRate);    
    }

    function mintReward (address account, uint256 share) internal 
    {
        // Calculate the time that has passed between the users last claim and the current block.
        uint256 timeElapsed = block.timestamp.sub(lastClaimTime[account]);

        // Get the percentage of GOTH to be minted to stakers
        uint256 allocation = 1000 - treasuryPercent - teamPercent;

        // We calculate total mint amounts for the pool, team and treasury, mint rate is not in wei
        // format, so we multiply it by 1e18 which moves the decimals 18 places to the required number
        // respresented in wei, this also provides precision. Additionally, since team and treasury 
        // are not further divided we multiply it by the time elapsed to get the correct mint amount
        // for those allocations.
        uint256 poolShare = mintRate.mul(allocation).div(1000);
        uint256 teamShare = mintRate.mul(1e18).mul(teamPercent).div(1000).mul(timeElapsed);
        uint256 treasuryShare = mintRate.mul(1e18).mul(treasuryPercent).div(1000).mul(timeElapsed);

        // Here, we calculate the stakers(user) share of the pool using the previously calculated pool allocation.
        // We multiplty the user share by 1e36, to ensure token precision, then we divide it by the total amount 
        // of GOTH within the pool and multiply it further by 100 to find the stakers share, as percentage
        // of the pool.
        uint256 stakerShare = share.mul(1e36).div(totalStaked).mul(100);
        // We calculate the reward amount by multiplying the pool share by the stakers share, then divide it by 100
        // and then 1e18, we could represent both of those divisions within one number, but this is clearer to see
        // that the 100 is a process of finding a percentage and then the 1e18 is the process of bringing the number back
        // down to the correct value after multiplying for token precision, this is then multiplied by the time elapsed
        // since last claim. 
        uint256 reward = poolShare.mul(stakerShare).div(100).div(1e18).mul(timeElapsed);

        // Each of the share amounts are minted, with the user amount being sent to their address, and the team
        // and treasury respectively.
        goth.mint(account, reward);
        goth.mint(teamAddress, teamShare);
        goth.mint(treasuryAddress, treasuryShare);

        // The users last claim time is updated with the current block timestamp.
        lastClaimTime[account] = block.timestamp;
    }

    function enter(uint256 amount) public nonReentrant payable
    {
        require(msg.value >= amount.div(enterFeeMod), "enter: supplied fee too little");
        require(goth.balanceOf(msg.sender) >= amount, "enter: not enough GOTH");

        // Check to see if the sender has GOTH staked already and if they do it will
        // gather the accrued rewards up until this point, this is to prevent a user from
        // entering the pool to boost their share for the sole purpose of gathering the reward
        // then withdrawing again.
        if (balanceOf(msg.sender) > 0)
        {
            mintReward(msg.sender, balanceOf(msg.sender));
        }

        // bGOTH is minted 1:1 to entered GOTH
        _mint(msg.sender, amount);
        goth.transferFrom(msg.sender, address(this), amount);    
        totalStaked = totalStaked.add(amount);

        // Users last claim time set to the current block timestamp
        lastClaimTime[msg.sender] = block.timestamp;

        emit Enter(msg.sender, amount);
    }

    function leave(uint256 share) public nonReentrant payable
    {
        require(msg.value >= leaveFee, "leave: supplied fee too little");
        require(balanceOf(msg.sender) >= share, "leave: not enough bGOTH");

        // We can remove part of, or all of the share. This is also taken into consideration
        // when minting the users reward based on how much they are removing from the pool.
        if (share == 0)
        {
            mintReward(msg.sender, balanceOf(msg.sender));
        }
        else
        {
            mintReward(msg.sender, balanceOf(msg.sender));

            _burn(msg.sender, share);
            goth.transfer(msg.sender, share);

            // We update total staked in the pool here, we do this because the balance of the account 
            // might be different from the total actually entered by stakers, this would mess with the 
            // rewards in a negative way.
            totalStaked = totalStaked.sub(share);

            emit Leave(msg.sender, share);
        }
    }

    // This calculates a users pending rewards without costing gas, it uses the same logic as the
    // mint reward function, but does not change the state of the contract.
    function accruedReward (address account) external view returns (uint256)
    {
        uint256 timeElapsed = block.timestamp.sub(lastClaimTime[account]);

        uint256 allocation = 1000 - treasuryPercent - teamPercent;

        uint256 poolShare = mintRate.mul(allocation).div(1000);

        uint256 stakerShare = balanceOf(account).mul(1e36).div(totalStaked).mul(100);
        uint256 reward = poolShare.mul(stakerShare).div(100).div(1e18).mul(timeElapsed);

        return reward;
    }

    // this function can only be called by the owner, and will withdraw all the avax at this contract
    // address and send it to the address defined by the feeAddress property within this contract.
    function withdrawFees () external onlyOwner
    {
        (bool sent, bytes memory data) = feeAddress.call{value: address(this).balance}("");
        require(sent, "withdrawFees: withdraw failed");
    }

    receive() external payable {}
    fallback() external payable {}
}