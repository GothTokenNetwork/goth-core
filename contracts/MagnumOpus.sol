// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./utils/Ownable.sol";
import "./utils/Sender.sol";

contract MagnumOpus is Ownable, Sender
{
    address private _gothSwap;
    address private _neonArkade;
    address private _courtOfTheMoon;
    address private _twilightMarket;

    constructor (address gothSwap_, address neonArkade_, address courtOfTheMoon_, address twilightMarket_) {
        _gothSwap = gothSwap_;
        _neonArkade = neonArkade_;
        _courtOfTheMoon = courtOfTheMoon_;
        _twilightMarket = twilightMarket_;
    }
}