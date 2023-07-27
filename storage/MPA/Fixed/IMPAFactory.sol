// SPDX-License-Identifier: None
pragma solidity 0.8.19;

interface IMPAFactory {
    function isManagement(address _addr) external view returns (bool);
}