// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./Vault.sol";

/**
* @title Ardoda Vault Factory.
* @author Etienne Cellier-Clarke
* @notice This is a factory used to deploy new Vault contracts onto the blockchain.
* @dev All function calls are currently implemented without side effects.
* @custom:propertyOf DreamKollab Ltd.
*/
contract VaultFactory {

    event newVault(address indexed creator, address indexed vault);

    address payable private owner;
    uint private creationFee;
    uint maxVaults;

    mapping(address => address[]) private users;

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

        Vault v = new Vault(msg.sender);

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
}