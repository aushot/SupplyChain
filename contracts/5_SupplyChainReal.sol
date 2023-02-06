// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

contract supplyChain {
    uint32 public product_id = 0;
    uint32 public partecipant_id = 0;
    uint32 public owner_id = 0;

    struct product {
        string modelNumber;
        string partNumber;
        string serialNumber;
        address productOwner;
        uint32 cost;
        uint32 mfgTimeStamp;
    }

    mapping(uint32 => product) public products;

    struct partecipant {
        string userName;
        string password;
        string partecipantType;
        address partecipantAddress;
    }
    mapping(uint32 => partecipant) public partecipants;

    struct ownership {
        uint32 productId;
        uint32 ownerId;
        uint32 trxTimeStamp;
        address productOwner;
    }

    mapping(uint32 => ownership) public ownerships;
    mapping(uint32 => uint32[]) public productTrack; //movements tracksj

    event TransferOwnership(uint32 product_id);

    function addPartecipant(string memory _name, string memory _pass, address _pAdd, string memory _pType) public returns (uint32 ){
        uint32 userId = partecipant_id++;
        partecipants[userId].userName = _name;
        partecipants[userId].password = _pass;
        partecipants[userId].partecipantAddress = _pAdd;
        partecipants[userId].partecipantType = _pType;

        return userId;
    }
    function getPartecipant(uint32 _product_id) public view returns (string memory, address, string memory) {
        return (partecipants[_product_id].userName, partecipants[_product_id].partecipantAddress, partecipants[_product_id].partecipantType);

    }
    function addProduct(uint32 _ownerId, string memory _modelNumber, string memory _partNumber, string memory _serialNumber, uint32 _productCost) public returns (uint32) {
        if(keccak256(abi.encodePacked(partecipants[_ownerId].partecipantType)) == keccak256("Manufacturer")) {
            uint32 productId = product_id++;

            products[product_id].modelNumber = _modelNumber;
            products[product_id].partNumber = _partNumber;
            products[product_id].serialNumber = _serialNumber;
            products[product_id].cost = _productCost;
            products[product_id].productOwner = partecipants[_ownerId].partecipantAddress;
            products[product_id].mfgTimeStamp = uint32(block.timestamp);

            return productId;
        }
    }
    modifier onlyOwner (uint32 _productId) {
        require(msg.sender == products[_productId].productOwner);
        _;
    }
    function getProduct (uint32 _productId) public view returns (string memory, string memory, string memory, uint32, address, uint32) {
        return (products[_productId].modelNumber,
        products[_productId].partNumber,
        products[_productId].serialNumber,
        products[_productId].cost,
        products[_productId].productOwner,
        products[_productId].mfgTimeStamp);
    }
    function newOwner(uint32 _user1Id, uint32 _user2Id, uint32 _prodId) onlyOwner(_prodId) public returns (bool) {
        partecipant memory p1 = partecipants[_user1Id];
        partecipant memory p2 = partecipants[_user2Id];
        uint32 ownership_id = owner_id++;
        
        if(keccak256(abi.encodePacked(p1.partecipantType)) == keccak256("Manufacturer") 
        && keccak256(abi.encodePacked(p2.partecipantType)) == keccak256("Supplier")){

            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.partecipantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            products[_prodId].productOwner = p2.partecipantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);

            return (true);
        } else if(keccak256(abi.encodePacked(p1.partecipantType)) == keccak256("Supplier") 
        && keccak256(abi.encodePacked(p2.partecipantType)) == keccak256("Supplier")) {

            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.partecipantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            products[_prodId].productOwner = p2.partecipantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);

            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.partecipantType)) == keccak256("Supplier") 
        && keccak256(abi.encodePacked(p2.partecipantType)) == keccak256("Consumer")) {
            
            ownerships[ownership_id].productId = _prodId;
            ownerships[ownership_id].productOwner = p2.partecipantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            products[_prodId].productOwner = p2.partecipantAddress;
            productTrack[_prodId].push(ownership_id);
            emit TransferOwnership(_prodId);

            return (true);
        }
    }
    function getProvenance(uint32 _prodId) external view returns (uint32[] memory){
        return productTrack[_prodId];
    }
    function getOwnership(uint32 _regId) public view returns (uint32, uint32, address, uint32){
        ownership memory r = ownerships[_regId];

        return (r.productId, r.ownerId, r.productOwner, r.trxTimeStamp);
    }

    function authenticatePartecipant(uint32 _uid, string memory _uname, string memory _pass, string memory _utype) public view returns (bool) {
        if(keccak256(abi.encodePacked(partecipants[_uid].partecipantType)) == keccak256(abi.encodePacked(_utype))) {
            if(keccak256(abi.encodePacked(partecipants[_uid].userName)) == keccak256(abi.encodePacked(_uname))) {
                if(keccak256(abi.encodePacked(partecipants[_uid].password)) == keccak256(abi.encodePacked(_pass))){
                    return (true);
                }
            }
        }
        return false;
    }
}