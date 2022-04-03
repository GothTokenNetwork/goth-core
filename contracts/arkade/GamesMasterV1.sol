// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IJoeRouter02 {

     function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

}

interface IJoePair {

    function token0() external view returns (address);
    function token1() external view returns (address);

}

contract GamesMasterV1 {

    IJoeRouter02 public pairAddress;
    IJoePair public pair;

}