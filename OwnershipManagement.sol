// SPDX-License-Identifier: MIT
import "./Ownable.sol";
pragma solidity ^0.8.0;

contract OwnershipManagement is Ownable {
    // Enums and Structs
    enum StakeholderType { Manufacturer, Distributor, Retailer, Customer }
    
    struct Stakeholder {
        address account;
        StakeholderType stakeholderType;
        string name;
        uint reputationScore;
    }
    
    struct Product {
        string productId;
        string name;
        uint quantity;
        address currentOwner;
        bool isRegistered;
    }
    
    struct Transaction {
        string productId;
        address from;
        address to;
        uint timestamp;
    }
 address public feeReceiver;// Declare the feeReceiver variable


function setFeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    // Dynamic receive function
    receive() external payable {
        // Forward received Ether to the fee receiver
        payable(feeReceiver).transfer(msg.value);
    }


    // Mappings
    mapping(address => Stakeholder) public stakeholders;
    mapping(string => Product) public products;
    mapping(address => string[]) public inventory;
    Transaction[] public transactions;
    
    // Events
    event StakeholderRegistered(address account, StakeholderType stakeholderType, string name);
    event ProductRegistered(string productId, string name, uint quantity, address owner);
    event ProductTransferred(string productId, address from, address to);
    event ReputationUpdated(address stakeholder, uint newScore);

    // Modifiers
    modifier onlyRegistered() {
        require(bytes(stakeholders[msg.sender].name).length > 0, "You must be a registered stakeholder.");
        _;
    }
    
    // Registration Functions
    function registerStakeholder(StakeholderType _type, string memory _name) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(stakeholders[msg.sender].account == address(0), "Stakeholder already registered.");
        
        stakeholders[msg.sender] = Stakeholder({
            account: msg.sender,
            stakeholderType: _type,
            name: _name,
            reputationScore: 100
        });
        
        emit StakeholderRegistered(msg.sender, _type, _name);
    }
    
    // Product Management Functions
    function registerProduct(string memory _productId, string memory _name, uint _quantity) public onlyRegistered {
        require(stakeholders[msg.sender].stakeholderType == StakeholderType.Manufacturer, "Only manufacturers can register products.");
        require(!products[_productId].isRegistered, "Product ID already exists.");
        
        products[_productId] = Product({
            productId: _productId,
            name: _name,
            quantity: _quantity,
            currentOwner: msg.sender,
            isRegistered: true
        });
        
        inventory[msg.sender].push(_productId);
        emit ProductRegistered(_productId, _name, _quantity, msg.sender);
    }
    
    function transferProduct(string memory _productId, address _to) public onlyRegistered {
        require(products[_productId].isRegistered, "Product is not registered.");
        require(products[_productId].currentOwner == msg.sender, "You are not the owner of this product.");
        require(stakeholders[_to].account != address(0), "Recipient must be a registered stakeholder.");
        
        // Update ownership
        products[_productId].currentOwner = _to;
        inventory[msg.sender].pop();
        inventory[_to].push(_productId);
        
        // Record transaction
        transactions.push(Transaction({
            productId: _productId,
            from: msg.sender,
            to: _to,
            timestamp: block.timestamp
        }));
        
        emit ProductTransferred(_productId, msg.sender, _to);
    }
    
    // Reputation Functions
    function updateReputation(address _stakeholder, uint _newScore) public onlyRegistered {
        require(_newScore <= 100, "Reputation score must be between 0 and 100.");
        require(stakeholders[_stakeholder].account != address(0), "Stakeholder must be registered.");
        
        stakeholders[_stakeholder].reputationScore = _newScore;
        emit ReputationUpdated(_stakeholder, _newScore);
    }

    // Getter Functions
    function getInventory(address _owner) public view returns (string[] memory) {
        return inventory[_owner];
    }

    function getTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }
}
