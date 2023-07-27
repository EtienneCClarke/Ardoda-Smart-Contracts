// SPDX-License-Identifier: None
pragma solidity 0.8.19;

interface IMAVault {

    function isOwner(address _user) external view returns (bool);
    function grantAccess(address _target) external;
    function revokeAccess(address _target) external;
}