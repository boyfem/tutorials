// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
Import "witnet-solidity-bridge/contracts/interfaces/IWitnetRandomness.sol";


contract Thrift{
   
    struct Club{
        string clubName;
    }
    struct Users{
     
        string userName;
        address userAddress;  
    }
   
    Users[] public user;
   


    mapping(string =>  Users[]) public clubToUser;
    mapping(string => uint256) public nameToAmount;
    mapping(string => uint256) public numberOfUsers;
    mapping(address => bool) public hasPaid;
    mapping(string => uint256 ) public totalAmountInClub;
    mapping(string => uint256) public trackOfUsersThatPaid;
      uint32 public randomness;
      uint time ;
    uint256 public latestRandomizingBlock;
    IWitnetRandomness immutable public witnet;
   
    /// @param _witnetRandomness Address of the WitnetRandomness contract.
    //This is Witnet Randomness Contract address that you would want to put as per your desired blockchain network given by https://docs.witnet.io/smart-contracts/supported-chains
    constructor (IWitnetRandomness _witnetRandomness) {
        assert(address(_witnetRandomness) != address(0));
        witnet = _witnetRandomness;
 time = block.timestamp;
    }
   
    receive () external payable {}


    function requestRandomNumber() external payable {
        latestRandomizingBlock = block.number;
        uint _usedFunds = witnet.randomize{ value: msg.value }();
        if (_usedFunds < msg.value) {
            payable(msg.sender).transfer(msg.value - _usedFunds);
        }
        time = block.timestamp;
    }
   
    function fetchRandomNumber(string memory _clubName)  public{
         assert(latestRandomizingBlock > 0);
            Users[] memory myarr = clubToUser[_clubName];
uint32 num = uint32(myarr.length);
   
     
     
 randomness = witnet.random(num , 0, latestRandomizingBlock);
    }
   


    function createClub(string memory _clubName, string memory _userName) public{
       
        Users memory clubUser =  Users(_userName, msg.sender);
         numberOfUsers[_clubName] = 1;
        clubToUser[_clubName].push(clubUser);
       
   
    }
    function addUser(string memory _clubName , string memory _userName, address _user) public{
        require(clubToUser[_clubName].length>0, "Club Not Found");
        Users memory clubUser = Users(_userName, _user);
         numberOfUsers[_clubName] += 1;
        clubToUser[_clubName].push(clubUser);
       
    }
 


    function proposedContirbutionAmount(string memory _clubName, uint256 _proposedAmount) public {
     uint256 amountInEther= _proposedAmount*10**18;
     nameToAmount[_clubName] = amountInEther;


    }
    function intervalInWeeks(string memory _clubName) public view returns(uint256){
      return numberOfUsers[_clubName];
    }


    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getAmountFromClub(string memory _clubName) public view returns(uint256){
        return nameToAmount[_clubName];
    }


    function sendAmountToContract(string memory _clubName) public payable{
        uint256 amount = getAmountFromClub(_clubName);
        // uint numberOfUsersInTheClub = numberOfUsers[_clubName];
        require(msg.value == amount , "please pay the correct amount" );
        require(hasPaid[msg.sender] == false , "User has already paid" );
        hasPaid[msg.sender] = true;
        trackOfUsersThatPaid[_clubName] += 1;
        totalAmountInClub[_clubName] += msg.value;
       
    }
    function hasEveryOnePaid (string memory _clubName) public returns (bool){
        return trackOfUsersThatPaid[_clubName] == numberOfUsers[_clubName];
    }
    function withdraw(string memory _clubName) public {
     require(block.timestamp > time + 600, "Please wait for 10 minutes until next transaction");
     require (hasPaid[msg.sender] == true , "User has not paid" );
        Users storage newArray = clubToUser[_clubName][randomness];
     fetchRandomNumber(_clubName);
     address payable _receiver = payable( newArray.userAddress);
     _receiver.transfer(totalAmountInClub[_clubName]);
     time = block.timestamp;
}
}