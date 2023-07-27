// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./Escrow.sol";

contract EscrowFactory {

    address payable private owner;
    address private manager;

    constructor() {
        owner = payable(msg.sender);
        manager = msg.sender;
    }

}