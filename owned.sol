pragma solidity ^0.4.24;

//代币管理者

contract Owned {

    address public owner; //代币管理者地址

    constructor() public {
        owner = msg.sender; //合约部署时，部署者为默认的代币管理者
    }

    //函数修饰器：只有代币管理者才能进行的操作(调用)
    modifier onlyOwner {
        require(msg.sender == owner); //要求调用者必须为管理者
        _;
    }

    //代币管理权限转移的方法
    function transferOwnerShip(address _newOwner) public onlyOwner { //使用了修饰器
        owner = _newOwner; //变更代币管理者
    }
}
