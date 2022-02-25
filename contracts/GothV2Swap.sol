// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./GothTokenV2.sol";
import "./Utils/SafeMath.sol";
import "./ERC20/IERC20.sol";

contract GothV2Swap is GothTokenV2
{
    using SafeMath for uint;

    IERC20 private _oldGoth;
    address private _burnAddress;

    constructor(IERC20 oldGoth_, address burnAddress_)
    {
        _oldGoth = oldGoth_;
        _burnAddress = burnAddress_;
    }

    receive() external payable { }

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

    function _swapForNewGoth (address sender, uint256 amount) internal virtual
    {
        require(_oldGoth.balanceOf(sender) >= amount, "old goth balance too low");
        require(_oldGoth.allowance(sender, address(this)) >= amount, "allowance too low");
        _oldGoth.transferFrom(sender, _burnAddress, amount);
        _transfer(address(this), sender, (amount.div(1000) + (amount.div(1000).div(10))));
    }
}