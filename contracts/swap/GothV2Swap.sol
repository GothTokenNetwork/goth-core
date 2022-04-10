// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./GothTokenV2.sol";
import "../utils/SafeMath.sol";
import "../erc20/IERC20.sol";

contract GothV2Swap is GothTokenV2
{
    using SafeMath for uint;

    IERC20 private _oldGoth;
    address private _burnAddress;
    address private _owner;

    constructor(IERC20 oldGoth_, address burnAddress_)
    {
        _oldGoth = oldGoth_;
        _burnAddress = burnAddress_;
        _owner = msg.sender;
    }

    receive() external payable { }

    function owner () public view virtual returns (address)
    {
        return _owner;
    }

    function oldGoth() public view virtual returns (address) 
    {
        return address(_oldGoth);
    }

    function burnAddress() public view virtual returns (address) 
    {
        return _burnAddress;
    }

    function swapForNewGoth (uint256 amount) public virtual returns (bool) 
    {
        _swapForNewGoth(msg.sender, amount);
        return true;
    }

    function withdraw (uint256 amount) public returns (bool)
    {
        _withdraw(msg.sender, amount);
        return true;
    }

    function changeOwner (address newOwner) public returns (bool)
    {
        _changeOwner(msg.sender, newOwner);
        return true;
    }

    function _swapForNewGoth (address sender, uint256 amount) internal virtual
    {
        require(_oldGoth.balanceOf(sender) >= amount, "old goth balance too low");
        require(_oldGoth.allowance(sender, address(this)) >= amount, "allowance too low");
        _oldGoth.transferFrom(sender, _burnAddress, amount);
        _transfer(address(this), sender, (amount.div(1000) + (amount.div(1000).div(10))));
    }

    function _withdraw (address sender, uint256 amount) internal virtual
    {
        require(sender == _owner, "denied");
        require(balanceOf(address(this)) >= amount, "funds too low in contract");
        _transfer(address(this), sender, amount);
    }
    
    function _changeOwner (address sender, address newOwner) internal virtual
    {
        require(sender == _owner, "denied");
        _owner = newOwner;
    }
}