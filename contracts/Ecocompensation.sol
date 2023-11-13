// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ecocompensation {
    address public owner;

    struct Transaction {
        string orderId;
        uint tCO2;
        uint euros;
        uint timestamp;
        address sender;
        string status;
        string Action; // Nouvelle variable pour l'action
    }

    struct CompanyInfo {
        string commercialContact;
        string companyName;
        string countryAddress;
        string commercialContactOwner;
        string ownerCountry;
        string billingName;
        string iban;
        string swiftcode;
    }

    Transaction[] public transactions;
    mapping(address => CompanyInfo) public companyInfos;
    mapping(string => uint) public tCO2compenseByOrderId;

    event Compensated(address indexed sender, string orderId, uint tCO2, uint euros, uint timestamp, string status, string Action);

    constructor() {
        owner = msg.sender;
        companyInfos[0x2399c5E218724954926B593A3dd164974197AA67] = CompanyInfo("Homer Simpson", "Donut", "9 rue des Moulins, Paris/France", "Matteo Cruz", "61 rues des Archives Paris/France", "Marge Simpson", "FR7629348811933", "EBATFRPPEB1");
        companyInfos[0xA3bf1810DAd6E40A9C4649E908165B011Ba7E6eE] = CompanyInfo("Mathilde Milka", "Cookie", "3 via Garibaldi Genova/Italie", "Matteo Cruz", "61 rues des Archives Paris/France", "Alain Milka", "FR7622999193948", "EBAPFRPPPSA");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function generateOrderId() private view returns (string memory) {
    bytes memory charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    bytes memory result = new bytes(6);
    uint256 charSetLength = charset.length;

    for (uint256 i = 0; i < 6; i++) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, transactions.length, i)));
        uint256 index = random % charSetLength;
        result[i] = charset[index];
    }

    return string(result);
}


    function compensate(uint _tCO2, uint _euros) public payable {
        require(_euros > 0, "Amount in euros must be greater than 0");
        string memory orderId = generateOrderId();
        tCO2compenseByOrderId[orderId] = 0;
        transactions.push(Transaction(orderId, _tCO2, _euros, block.timestamp, msg.sender, "Nouveau", ""));
        payable(owner).transfer(msg.value);
        emit Compensated(msg.sender, orderId, _tCO2, _euros, block.timestamp, "Nouveau", "");
    }

    function getTransactionsCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint index) public view returns (string memory orderId, uint tCO2, uint euros, uint timestamp, address sender, string memory status, string memory Action) {
        require(index < transactions.length, "Transaction index out of bounds");
        Transaction storage transaction = transactions[index];
        return (transaction.orderId, transaction.tCO2, transaction.euros, transaction.timestamp, transaction.sender, transaction.status, transaction.Action);
    }

    function getCompanyInformation(address _companyAddress) public view returns (string memory, string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        CompanyInfo storage companyInfo = companyInfos[_companyAddress];
        return (companyInfo.commercialContact, companyInfo.companyName, companyInfo.countryAddress, companyInfo.commercialContactOwner, companyInfo.ownerCountry, companyInfo.billingName, companyInfo.iban, companyInfo.swiftcode);
    }

    function addToTco2(string memory _orderId, uint _additionalTco2, string memory _newAction) public onlyOwner {
        bool found = false;
        for (uint i = 0; i < transactions.length; i++) {
            if (keccak256(abi.encodePacked(transactions[i].orderId)) == keccak256(abi.encodePacked(_orderId))) {
                uint totalTCO2 = tCO2compenseByOrderId[_orderId] + _additionalTco2;
                require(totalTCO2 <= transactions[i].tCO2, "Total compensated tCO2 exceeded for this transaction");
                tCO2compenseByOrderId[_orderId] = totalTCO2;
                transactions[i].Action = string(abi.encodePacked(transactions[i].Action, " | ", _newAction));
                if (totalTCO2 == transactions[i].tCO2) {
                    transactions[i].status = "Complete";
                }
                found = true;
                break;
            }
        }
        require(found, "OrderID not found");
    }

    function getTco2CompenseByOrderId(string memory _orderId) public view returns (uint) {
        return tCO2compenseByOrderId[_orderId];
    }

    function getSenderAddress() public view returns (address) {
        return msg.sender;
    }

    function getRegisteredAddresses() public view returns (address[] memory) {
        address[] memory addresses = new address[](transactions.length);
        for (uint i = 0; i < transactions.length; i++) {
            addresses[i] = transactions[i].sender;
        }
        return addresses;
    }
}
