pragma solidity ^0.4.24;

//开发实现ERC-20标准协议的代币合约

import "./erc20interface.sol";

contract ERC20 is ERC20Interface { //合约继承标准

    mapping(address => uint256) public balanceOf; //定义存储账本的mapping
    mapping(address => mapping(address => uint256)) public allowed; //记录委托行为:“委托人”授权“被委托人”管理一定数目的资产

    //构造函数，初始化接口协议中的状态变量,初始化可以直接写，也可以通过参数传进来
    constructor(string _name) public{ //代币名称部署时手写
        name = _name; //"EddieChain"
        symbol = "EDT"; 
        decimals = 0; //最低交易金额为1个EDT
        totalSupply = 1000000; //总供应量1百万
        balanceOf[msg.sender] = totalSupply; //将发行的代币全部给合约部署者
    } 

    //转账函数
    function transfer(address _to, uint256 _value) public returns(bool success) {

        require(_to != address(0)); //目标账号为空判断
        require(balanceOf[msg.sender] >= _value); //余额充足判断
        require(balanceOf[_to] + _value >= balanceOf[_to]); //转账溢出判断

        balanceOf[msg.sender] -= _value; //付款账号减
        balanceOf[_to] += _value; //接收账号加

        emit Transfer(msg.sender, _to, _value); //触发事件，添加日志
        success = true; //转账成功 返回ture 返回值有参数,相当于return true
    }

    //授权后的转账
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {

        require(_to != address(0)); //目标账号为空判断
        require(allowed[_from][msg.sender] >= _value); //既检查调用者是否是被委托者，又检查被授权的金额是否足够转账
        require(balanceOf[_from] >= _value); //余额充足判断
        require(balanceOf[_to] + _value >= balanceOf[_to]); //转账溢出判断

        balanceOf[_from] -= _value; //付款账号减
        balanceOf[_to] += _value; //接收账号加
        allowed[_from][msg.sender] -= _value; //被授权的额度也要减少

        emit Transfer(_from, _to, _value); //触发事件，添加日志
        success = true; //转账成功 返回ture 返回值有参数,相当于return true
    }

    //授权函数 调用者授权被委托者 管理一定数额资产
    function approve(address _spender, uint256 _value) public returns(bool success) {

        allowed[msg.sender][_spender] = _value; //存储授权数据 委托者msg.sender, 被委托者_spender, 金额_value

        emit Approval(msg.sender, _spender, _value); //触发事件，添加日志
        success = true;
    }
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {

        remaining = allowed[_owner][_spender]; //返回授权记事本中授权余额 注意返回值带参数时的return写法
    }
}
