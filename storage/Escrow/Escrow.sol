// SPDX-License-Identifier: None
pragma solidity 0.8.19;

enum state {
    AWAITING_ACCEPT,
    AWAITING_PAYMENT,
    CONFIRMED_PAYMENT,
    WORK_COMPLETE,
    IN_DISPUTE,
    CLOSED
}

contract Escrow {

    event Notice(string message);

    address payable private factory;
    address private buyer;

}