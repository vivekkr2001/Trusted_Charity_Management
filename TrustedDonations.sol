// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Trusted_charity_management
/// @author Vivek Kumar
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract TrustedDonations {
    uint public totalCollection=0;
    uint public requirement=0;

    uint public totalDonations;
    uint public totalCharity;
    uint public totalBeneficiaries;

    struct Donation {
        uint donateAmount;
        address donorAddr;
        string donorName;
        uint time;
    }

    struct Owner{                                                                
        string[] name;
        address[] ownerAddr;
        uint funds;
        uint requiredFunds;
    }

    struct Beneficiary{
        string name;
        address addr;
        uint bReq;
        uint bLeft;
    }

    struct Payment{
        uint paidAmount;
        address beneficiaryAddr;
        address ownerId;
        uint time;
    }

    Donation[] public DonationList;
    Owner public owner;
    mapping(address => bool) doesOwnExist;
    Beneficiary[] public beneficiaries;
    mapping(address => bool) doesBenExist;
    Payment[] public PaymentList;
                                        
    constructor (string memory _ownerName) {
        owner.name.push(_ownerName);
        owner.ownerAddr.push(msg.sender);
        owner.funds = 0;
        owner.requiredFunds =0;
        doesOwnExist[msg.sender] = true;

        totalCharity = 0;
        totalDonations = 0;
    }

    function addBeneficiary(string memory _name, address accNo, uint required) public{
        require(doesOwnExist[msg.sender] == true, "Permission Denied, Not an Owner");
        require(doesBenExist[accNo] == false, "Beneficiary already exist");
        beneficiaries.push(Beneficiary({
            name : _name,
            addr : accNo,
            bReq : required,
            bLeft: required
            }
        ));
        owner.requiredFunds += required;
        doesBenExist[accNo] = true;
        totalBeneficiaries++;
    }

    function deleteBeneficiary(address accountNum) public {
        require(doesBenExist[accountNum] == true, "Beneficiary doesn't exist.");
        uint index = 0;
        for (uint i=0; i< beneficiaries.length; i++) {
            if (accountNum == beneficiaries[i].addr) {
                index = i;
                break;
            }
        }

        beneficiaries[index] = beneficiaries[beneficiaries.length - 1];
        owner.requiredFunds = owner.requiredFunds - beneficiaries[index].bReq;
        beneficiaries.pop();
        doesBenExist[accountNum] = false;
        totalBeneficiaries--;
    }

    function makeDonation(
            string memory _donorName 
        ) public payable returns(string memory)
    {
        if (msg.value < 1 gwei) {
            revert("Not enough donation to record");
        }

        owner.funds += msg.value;
        
        DonationList.push(Donation({
            donorName: _donorName,
            donorAddr: msg.sender,
            donateAmount: msg.value,
            time: block.timestamp
        }));
        totalCollection += msg.value;
        totalDonations++;
        return "Made a donation!" ;
    }

    function getCollectedFund() public view returns (uint){
        return owner.funds;
    }

    function getRequiredFund() public view returns (uint){
        return owner.requiredFunds - owner.funds;
    }

    function findBeneficiary(address accountId) public view returns (string memory result){
        require(doesBenExist[accountId] == true, "Beneficiary does not exist");

        for (uint i=0; i< beneficiaries.length; i++) {
            if (accountId == beneficiaries[i].addr) {
                return beneficiaries[i].name;
            }
        }
    }

    function payBeneficiary(address payable accountId, uint fund) external{
        require(doesOwnExist[msg.sender] == true, "Permission Denied, Not an Owner");
        require(doesBenExist[accountId] == true, "Beneficiary doesn't exist.");

        uint index = 0;
        for (uint i=0; i< beneficiaries.length; i++) {
            if (accountId == beneficiaries[i].addr) {
                index = i;
                break;
            }
        }
        uint payAmount = fund;
        if(beneficiaries[index].bLeft <= fund){
            payAmount = beneficiaries[index].bLeft;
        }

        beneficiaries[index].bLeft = beneficiaries[index].bLeft - payAmount;
        
        owner.funds = owner.funds - payAmount;
        owner.requiredFunds = owner.requiredFunds - payAmount;
 
        PaymentList.push(Payment({
            paidAmount: payAmount,
            beneficiaryAddr: accountId,
            ownerId: msg.sender,
            time: block.timestamp
        }));

        totalCharity++;
        accountId.transfer(payAmount);

    }
    
}
