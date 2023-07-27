// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./MAVault.sol";
import "./IMAVault.sol";

/**
* @title Ardoda Vault Factory.
* @author Etienne Cellier-Clarke
* @notice This is a factory used to deploy new Vault contracts onto the blockchain.
* @dev All function calls are currently implemented without side effects.
* @custom:propertyOf DreamKollab Ltd.
*/
contract MAVaultFactory {

    event newVault(address indexed creator, address indexed vault);

    address payable private owner;
    uint private creationFee;
    uint maxVaults;

    mapping(address => address[]) private users;
    mapping(address => address[]) private accessible;

    constructor() {
        owner = payable(msg.sender);
        creationFee = 0;
        maxVaults = 5;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Denied.");
        _;
    }

    /**
    * @notice A new vault is created for the transaction sender.
    */
    function createVault() external payable {
        require(msg.value == creationFee, "Error: msg.value Incorrect.");
        require(users[msg.sender].length < maxVaults, "Error: Cannot create more Vaults.");

        MAVault v = new MAVault(msg.sender);

        users[msg.sender].push(address(v));

        emit newVault(msg.sender, address(v));
    }

    /**
    * @notice Fetch list of vaults owned by an address.
    * @param _user Target address.
    * @return array List of Vault addresses.
    */
    function getVaults(address _user) external view returns (address[] memory) {
        return users[_user];
    }

    /**
    * @notice Fetch list of accesible vaults for target address.
    * @param _user Target address.
    * @return array List of Vault addresses.
    */
    function getAccessibleVaults(address _user) external view returns (address[] memory) {
        return accessible[_user];
    }

    /**
    * @notice Change owner of this factory contract.
    * @param _newOwner Address to be assigned as owner.
    */
    function changeOwner(address _newOwner) onlyOwner external {
        owner = payable(_newOwner);
    }

    /**
    * @notice Change the max number of vaults an address can own.
    * @param _newMax New number of vaults an address can own.
    */
    function changeMaxVaults(uint _newMax) onlyOwner external {
        maxVaults = _newMax;
    }

    /**
    * @notice Removes access to vault for target address.
    * @param _target Address to remove.
    */
    function revokeAccess(address _vault, address _target) external {
        
        require(IMAVault(_vault).isOwner(msg.sender), "Error: Access denied.");

        address[] memory arr = new address[](accessible[_target].length - 1);
        uint index = 0;
        for(uint i = 0; i < accessible[_target].length; i++) {
            if(accessible[_target][i] != _vault) {
                arr[index] = users[_target][i];
                index++;
            }
        }
        accessible[_target] = arr;

    }

    /**
    * @notice Grants access to vault for target address.
    * @param _target Target address.
    */
    function grantAccess(address _vault, address _target) external {

        require(IMAVault(_vault).isOwner(msg.sender), "Error: Access denied.");

        accessible[_target].push(_target);
        IMAVault(_vault).grantAccess(_target);
    }

    /**
    * @notice Transfers ownership of vault;
    * @param _vault Address of vault to be transferred.
    * @param _target Target address that will become the new owner.
    */
    function transferVault(address _vault, address _target) external {
        
        require(users[_target].length < maxVaults, "Error: Transfer failed, target address has reach max vaults.");
        require(IMAVault(_vault).isOwner(msg.sender), "Error: Access denied.");
        
        // remove vault from user
        address[] memory arr = new address[](users[msg.sender].length - 1);
        uint index = 0;
        for(uint i = 0; i < users[msg.sender].length; i++) {
            if(users[msg.sender][i] != _vault) {
                arr[index] = users[msg.sender][i];
                index++;
            }
        }
        users[msg.sender] = arr;

        users[_target].push(_vault);

        IMAVault(_vault).changeOwner(_target);
    }
}