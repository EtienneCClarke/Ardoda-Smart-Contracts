// SPDX-License-Identifier: None
pragma solidity 0.8.19;

interface ITimelockVault {
    function changeOwner(address _newOwner) external;
    function isOwner(address _user) external view returns (bool);
}