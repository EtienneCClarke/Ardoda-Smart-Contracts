// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

contract Auto_Transfer {

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        require(msg.value > 0, 'Enter a valid amount.');
        owner.transfer(address(this).balance);
    }

    function sponge() external payable {}

}