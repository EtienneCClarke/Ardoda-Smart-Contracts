// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/utils/Strings
// License: MIT
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
* @title Kollab Share Contract Factory.
* @author DSDK Technologies.
* @notice You can use this factory to create and interface with kollab shares.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Factory {

    address payable private owner;

    uint32 creationFee;
    uint32 transactionFee;
    uint64 idCounter;

    mapping(uint64 => Kollab_Share) private kollabs;
    mapping(address => uint64) private kollabIDs;
    mapping(address => uint64[]) private asocKollabs;
    mapping(address => uint64[]) private createdKollabs;

    modifier onlyOwner {
        require(msg.sender == owner, 'Access Denied');
        _;
    }
    
    /**
    * @notice Executed when contract is deployed. Defines the owner.
    * of the contract, as the message sender. It also sets the initial
    * fee values.
    */
    constructor() {
        owner = payable(msg.sender);
        creationFee = 10000;
        transactionFee = 10000;
        idCounter = 0;
    }

    receive() external payable {}

    /**
    * @notice Use this contract to create a new kollab share.
    * @param _name Name of the contract.
    */
    function create(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint64[] memory _shares
    ) external payable {

        uint64 id = newID();

        require(!exists(id), 'Error Generating UUID');
        // require(msg.value >= creationFee / 1000000, 'Insufficient creation fee.');
        require(bytes(_name).length <= 20, 'Name cannot be more than 20 characters');
        require(
            bytes(_description).length <= 50,
            'Description cannot be more than 50 characters'
        );
        require(
            _payees.length == _shares.length,
            'Error allocating shares to each payee.'
        );

        uint64 total_shares;
        for(uint16 i = 0; i < _shares.length; i++) {
            total_shares += _shares[i];
        }

        require(total_shares <= 1000000000000, 'Total shares can not exceed one trillion.');

        kollabs[id] = new Kollab_Share(
            _name,
            _description,
            _payees,
            _shares,
            total_shares,
            transactionFee,
            msg.sender,
            address(this)
        );

        for(uint16 i = 0; i < _payees.length; i++) {
            asocKollabs[_payees[i]].push(id);
        }

        createdKollabs[msg.sender].push(id);
        
        // add to ids mapping

    }

    /**
    * @notice Retrieve all data (except shareholders) about a specific kollab share.
    * @param _id UUID used to identify which kollab share to access.
    * @return result An array of strings which contains the collated data.
    */
    function getShareData(uint64 _id, address _account) public view returns (string[] memory) {

        string[] memory result = new string[](9);
        if(!exists(_id)) { return result; }

        Kollab_Share ks = kollabs[_id];

        result[0] = Strings.toHexString(address(ks)); // Address
        result[1] = ks.getName(); // Name
        result[2] = ks.getDescription(); // Description
        result[3] = Strings.toString(ks.getPayeeShares(_account)); // Personal shares
        result[4] = Strings.toString(ks.getTotalShares()); // Total shares
        result[5] = Strings.toString(ks.getUserBalance(_account)); // Personal Balance
        result[6] = Strings.toString(address(ks).balance); // Total Balance
        result[7] = Strings.toString(ks.getLastWithdrawl(_account)); // Last withdrawl blockstamp
        result[8] = Strings.toHexString(ks.getCreator()); // Creator or splitter
        return result;
    }

    /**
    * @notice Generates a new unique identifier.
    * @return uint64 The value of idCounter + 1.
    */
    function newID() private returns (uint64) {
        return ++idCounter;
    }

    /**
    * @notice Allows the retrieval of all UUIDs associated with an address
    * where the address is a payee of a kollab share.
    * @param _account Address of account to retrieve UUIDs for.
    * @return UUIDs An array of UUIDs.
    */
    function getIds(address _account) public view returns (uint64[] memory) {
        return asocKollabs[_account];
    }

    /**
    * @notice Allows the retrieval of all UUIDs associated with an address
    * where the address is a creator of a kollab share.
    * @param _account Address of account to retrieve UUIDs for.
    * @return UUIDs An array of UUIDs.
    */
    function getCreatedIds(address _account) public view returns (uint64[] memory) {
        return createdKollabs[_account];
    }

    /**
    * @notice Retrieves all shareholders and their number of assigned shares.
    * @param _id UUID of a kollab share.
    * @return sharholders An array containing each address and associated shares
    * founnd within a kollab share. 
    */
    function getShareholders(uint64 _id) public view returns (string[] memory) {
        return kollabs[_id].getShareholders();
    }

    /**
    * @notice Allows only the contract owner to change the creation fee
    * as long as the new fee is not less than 0.
    * @param _fee The new fee value which will be used henceforth.
    */
    function changeCreationFee(uint32 _fee) onlyOwner public {
        require(_fee >= 0, 'Value cannot be less than 0.');
        creationFee = _fee;
    }

    /**
    * @notice Allows only the contract owner to change the transaction fee
    * as long as the new fee is not less than 0. When a fee is changed it will
    * only apply to new kollab shares being created.
    * @param _fee The new fee value which will be used henceforth.
    */
    function changeTransactionFee(uint32 _fee) onlyOwner public {
        require(_fee >= 0, 'Value cannot be less than 0.');
        creationFee = _fee;
    }

    /**
    * @notice The owner of the contract can release accumulated fees to their wallet.
    * @param _amount The amount of fees to be released.
    */
    function releaseFees(uint _amount) onlyOwner public {
        owner.transfer(_amount);
    }

    /**
    * @notice Allows a payee to withdraw available funds from a kollab share.
    * @param _id UUID of a kollab share.
    */
    function payout(uint64 _id) external {
        kollabs[_id].payout(msg.sender);
    }

    /**
    * @notice Allows the creator of a kollab share to release the funds to all payees.
    * @param _id UUID of a kollab share.
    */
    function payoutAll(uint64 _id) external {
        kollabs[_id].payoutAll(msg.sender);
    }


    /**
    * @notice Checks whether a unique universal identifier already exists.
    * @param _id UUID to be checked.
    * @return bool true if UUID exists, false if not.
    */
    function exists(uint64 _id) private view returns (bool) {
        if(address(kollabs[_id]) != address(0)) {
            return true;
        }
        return false;
    }
}

/**
* @title Kollab Share Contract.
* @author DSDK Technologies.
* @notice A kollab share is a collection of crypto addresses each with an assigned number of shares.
* Once a kollab share has been created it can no longer be modified and all share values are fixed.
* If a payee wants to withdraw any monies from the kollab share they can only withdraw the amount
* they are entitled to which is determined by the amount of shares they have been allocated.
* The creator of the kollab share has the ability to flush the contract and all payees will be
* transferred their share of any monies remaining.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Kollab_Share {

    address factory;

    address creator;
    string name;
    string description;
    uint64 total_shares = 0;
    uint total_revenue = 0;
    uint32 fee;
    address[] payees;
    mapping(address => uint) shareholders;
    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;

    /**
    * @notice Executed when a new kollab share is created.
    * @param _name Name of the kollab share (max 20 characters).
    * @param _description Description of the kollab share (max 50 characters).
    * @param _payees This is an array of addresses of all the payees to be stored
    * within the kollab share contract.
    * @param _shares This is an array of values which stores the number of shares
    * for each shareholder.
    * @param _total_shares This is the total number of shares allocated.
    * @param _fee This is a fixed value which determines the fee paid when monies
    * are withdrawn from the wallet.
    * @param _creator This is the address of the wallet which called for a new
    * contract to be created and alloted the shares for all payees.
    */
    constructor(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint64[] memory _shares,
        uint64 _total_shares,
        uint32 _fee,
        address _creator,
        address _factory
    ) {
        name = _name;
        description = _description;
        total_shares = _total_shares;
        payees = _payees;
        fee = _fee;
        creator = _creator;
        factory = _factory;

        for(uint16 i = 0; i < _payees.length; i++) {
            shareholders[_payees[i]] = _shares[i];
        }
    }

    modifier onlyCreator {
        require(msg.sender == factory, 'Only the creator has access to this functionality.');
        _;
    }

    /**
    * @notice Executed when a payment is made to the contract address.
    */
    receive() external payable {
        require(msg.value > 0, 'Enter valid amount.');
        total_revenue = total_revenue + msg.value;
    }

    /**
    * @notice Retrieves creator address of the kollab share.
    * @return creator Address of creator.
    */
    function getCreator() public view returns (address) {
        return creator;
    }

    /**
    * @notice Retrieves name of kollab share.
    * @return name Name of kollab share.
    */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
    * @notice Retrieves description of kollab share.
    * @return description Description of kollab share.
    */
    function getDescription() public view returns (string memory) {
        return description;
    }

    /**
    * @notice Retieves shares of a specific payee.
    * @return shares Shares owned by a payee within the kollab share.
    */
    function getPayeeShares(address _payee) public view returns (uint) {
        return shareholders[_payee];
    }

    /**
    * @notice Retrieves total number of shares within a kollab share. 
    * @return total_shares Total number of shares.
    */
    function getTotalShares() public view returns (uint) {
        return total_shares;
    }

    /**
    * @notice Calculates available balance within the kollab share.
    * @return balance Remaning balance.
    */
    function getUserBalance(address _payee) public view returns (uint256) {
        return ( shareholders[_payee] * total_revenue ) / total_shares - total_released[_payee];
    }

    /**
    * @notice Retrieves the timestamp when a payee last made a withdrawl.
    * @return time Unix timestamp.
    */
    function getLastWithdrawl(address _payee) public view returns (uint) {
        return last_withdrawl[_payee];
    }

    /**
    * @notice Checks is a payee is a shareholder within a kollab share.
    * @param _payee Address to be checked.
    * @return bool true if payee is a shareholder, false if not.
    */
    function isPayee(address _payee) public view returns (bool) {
        for(uint i = 0; i < payees.length; i++) {
            if(_payee == payees[i]) { return true; }
        }
        return false;
    }

    /**
    * @notice Retrieves all shareholders and their number of allocated shares
    * within the kollab share
    * @return _shareholders An array containing each address and associated shares
    * found within a kollab share.
    */
    function getShareholders() public view returns (string[] memory) {
        string[] memory _shareholders = new string[](payees.length * 2);

        uint j = 0;
        for(uint i = 0; i < payees.length; i++) {
            address _payee = payees[i];
            _shareholders[j] = Strings.toHexString(_payee);
            _shareholders[j + 1] = Strings.toString(shareholders[_payee]);
            j = j + 2;
        }

        return _shareholders;
    }

    /**
    * @notice Transfers payee their available balance. Can only be executed
    * by a payee.
    */
    function payout(address _account) external {

        require(msg.sender == factory, 'Can only be accessed through the contract factory.');
        require(this.isPayee(_account), 'Account provided is not a shareholder.');
        require(shareholders[_account] > 0, 'Account has no shares.');
        require(address(this).balance > 0, 'Insufficient funds within contract.');
        
        uint available_funds = this.getUserBalance(_account);
        uint transaction_fee = ( available_funds / 10000000 ) * fee;

        require(available_funds > 0, 'Insufficient balance.');

        payable(_account).transfer(available_funds - transaction_fee);
        payable(factory).transfer(transaction_fee);
        total_released[_account] += available_funds;
        last_withdrawl[_account] = block.timestamp;
    }

    /**
    * @notice Transfers all payees their available balance. Can only be executed
    * by the creator of the kollab share.
    */
    function payoutAll(address _account) external {

        require(msg.sender == factory, 'Can only be accessed through the contract factory.');
        require(_account == creator, 'Only the creator of this splitter can release all funds.');
        require(address(this).balance > 0, 'Insufficient funds.');

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];

            if(shareholders[payee] < 0) { continue; }

            uint available_funds = this.getUserBalance(payee);
            uint transaction_fee = ( available_funds / 1000 ) * fee;
            if(available_funds > 0) {
                payable(payee).transfer(available_funds - transaction_fee);
                payable(factory).transfer(transaction_fee);
                total_released[payee] += available_funds;
                last_withdrawl[payee] = block.timestamp;
            }
        }
    }


}