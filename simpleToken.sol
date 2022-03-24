pragma solidity ^0.4.24;

/*
 * @date:2022.3.19春分
 * @title:实现一个简单代币
 * @author:eddie
 */ 

contract SimpleToken {

    mapping(address => uint256) public balanceOf; //用来保存账本信息

    //构造函数
    //@param:initialSupply 代币初始供应量
    //@dev:创建代币时，最初的供应量全部给创建者
    constructor(uint256 initialSupply) public {

        balanceOf[msg.sender] = initialSupply; //创建者地址获得全部初始发行量
    }

    //转账函数
    function transfer(address _to, uint256 _value) public {

        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value); //检查：转出账户余额是否足够
        require(balanceOf[_to] + _value >= balanceOf[_to]); //检查：如果转账，目标账号是否发生溢出

        balanceOf[msg.sender] -= _value; //调用者（转出者）账号做减法
        balanceOf[_to] += _value; //接收者（目标账号）账号做加法
    }
} 
