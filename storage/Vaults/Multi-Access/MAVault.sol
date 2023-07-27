// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

/**
* @title Ardoda Vault.
* @author Etienne Cellier-Clarke
* @notice This is a vault for ERC-20, ERC-721, and ERC-1155 Tokens. The owner can
* store and withdraw these tokens as they chose.
* @dev All function calls are currently implemented without side effects.
* @custom:propertyOf DreamKollab Ltd.
*/
contract MAVault {

    event Withdraw(address indexed executor, uint indexed amount);
    event WithdrawERC20(address indexed executor, address indexed token, uint indexed amount);
    event WithdrawERC721(address indexed executor, address indexed token, uint indexed tokenID);
    event WithdrawERC1155(address indexed executor, address indexed token, uint tokenID, uint value);
    event WithdrawBatchERC1155(address indexed executor, address indexed token, uint[] tokenIDs, uint[] values);

    address private owner;
    address private factory;
    
    address[] private whitelist;
    mapping(address => bool) private permissions;

    constructor(address _owner, address _factory) {
        factory = _factory;
        owner = _owner;
        permissions[_owner] = true;
        whitelist.push(_owner);
    }

    receive() external payable {}
    fallback() external payable {}

    modifier restricted {
        require(permissions[msg.sender], "Denied.");
        _;
    }

    /**
    * @notice Checks if an address is the owner of this vault.
    * @param _user Address to check.
    * @return bool Returns true if _user is vault owner.
    */
    function isOwner(address _user) external view returns (bool) {
        if(_user == owner) {
            return true;
        }
        return false;
    }

    /**
    * @notice Transfers ownership of vault.
    * @param _newOwner Target address to become new owner.
    */
    function changeOwner(address _newOwner) external {
        require(msg.sender == factory, "Only the owner can execute this.");
        owner = payable(_newOwner);
    }

    /**
    * @notice Fetches addreses that have access to this vault.
    * @return array Array of addreses.
    */
    function getWhitelist() external view returns (address[] memory) {
        return whitelist;
    }

    /**
    * @notice grants access to vault for target address
    * @param _target Target address
    */
    function grantAccess(address _target) external {
        require(msg.sender == factory, "Denied.");
        require(whitelist.length < 25, "Denied.");

        whitelist.push(_target);
        permissions[_target] = true;

    }

    /**
    * @notice Removes access to the vault for target address.
    * @param _target Address to remove.
    */
    function revokeAccess(address _target) external {
        require(msg.sender == factory, "Denied.");

        address[] memory arr = new address[](whitelist.length - 1);
        uint index = 0;
        for(uint i = 0; i < whitelist.length; i++) {
            if(whitelist[i] != _target) {
                arr[index] = whitelist[i];
            }
        }
        whitelist = arr;
        delete permissions[_target];
    }
    
    /**
    * @notice Handle the receipt of ERC-721 tokens (NFT).
    * @param all Refer to EIP-721 standard (https://eips.ethereum.org/EIPS/eip-721).
    * @return bytes4 Fixed-length array of four bytes 0x150b7a02.
    */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
    * @notice Handle the receipt of ERC-1155 tokens (NFT).
    * @param all Refer to EIP-1155 standard (https://eips.ethereum.org/EIPS/eip-1155).
    * @return bytes4 Fixed-length array of four bytes 0x150b7a02.
    */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
    * @notice Handle the receipt of multiple ERC-1155 token types (NFT).
    * @param all Refer to EIP-1155 standard (https://eips.ethereum.org/EIPS/eip-1155).
    * @return bytes4 Fixed-length array of four bytes 0x150b7a02.
    */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
    * @notice Transfers a specified amount of the native token to the vault owner.
    * @param _amount Amount in WEI to transfer.
    */
    function withdraw(uint _amount) restricted external {
        require(_amount <= address(this).balance, "Insufficient Funds");
        transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
    * @notice Transfers a specified amount of an ERC-20 token to the vault owner.
    * @param _token Source address.
    * @param _amount Amount in WEI to transfer.
    */
    function withdrawERC20(IERC20 _token, uint _amount) restricted external {
        require(_amount <= _token.balanceOf(address(this)), "Insuffucient Funds.");
        _token.transfer(msg.sender, _amount);
        emit WithdrawERC20(msg.sender, address(_token), _amount);
    }

    /**
    * @notice Transfers an ERC-721 token to the vault owner.
    * @param _token Source address.
    * @param _tokenID Token Identifier.
    */
    function withdrawERC721(IERC721 _token, uint256 _tokenID) restricted external {
        _token.safeTransferFrom(address(this), msg.sender, _tokenID);
        emit WithdrawERC721(msg.sender, address(_token), _tokenID);
    }

    /**
    * @notice Transfers an ERC-1155 token to the vault owner.
    * @param _token Source address.
    * @param _tokenID Token Identifier.
    * @param _value Number of tokens to transfer.
    * @param _data Additional data with no specified format
    */
    function withdrawERC1155(IERC1155 _token, uint256 _tokenID, uint256 _value, bytes calldata _data) restricted external {
        _token.safeTransferFrom(address(this), msg.sender, _tokenID, _value, _data);
        emit WithdrawERC1155(msg.sender, address(_token), _tokenID, _value);
    }

    /**
    * @notice Transfers an ERC-1155 token to the vault owner.
    * @param _token Source address.
    * @param _tokenIDs IDs of each token type (order and length must match _values array)
    * @param _values Transfer amounts per token type (order and length must match _ids array)
    * @param _data Additional data with no specified format
    */
    function withdrawBatchERC1155(IERC1155 _token, uint256[] calldata _tokenIDs, uint256[] calldata _values, bytes calldata _data) restricted external {
        _token.safeBatchTransferFrom(address(this), msg.sender, _tokenIDs, _values, _data);
        emit WithdrawBatchERC1155(msg.sender, address(_token), _tokenIDs, _values);
    }
    
    // https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    function transfer(address _to, uint _amount) private {
        bool callStatus;
        assembly {
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        if(!callStatus) revert TransferFailed();
    }
}