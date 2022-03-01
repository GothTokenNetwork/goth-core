// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

abstract contract Sender 
{
    event Received(address, uint, uint256);
    event Send(address, uint, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value, gasleft());
    }

    function send(address payable to) payable public {
        require(msg.value >= address(this).balance, "Not enough AVAX");
        to.transfer(msg.value);
        emit Send(to, msg.value, gasleft());
    }
}

    