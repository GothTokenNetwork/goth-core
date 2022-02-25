// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./GothV2Swap.sol";

contract GothSwapController 
{
    GothV2Swap private _gothV2Swap;

    constructor (IERC20 oldGoth_, address burnAddress_)
    {
        _gothV2Swap = new GothV2Swap(oldGoth_, burnAddress_);
    }

    function gothV2Swap() public view virtual returns (address)
    {
        return address(_gothV2Swap);
    }
}