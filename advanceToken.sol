pragma solidity ^0.4.24;

//实现ERC-20标准且实现代币增发的高级代币合约

import "./erc20.sol";
import "./owned.sol";

contract AdvanceToken is ERC20, Owned { //继承ERC20合约及代币管理合约

    mapping(address => bool) public frozenAccount; //储存账户冻结状态的变量

    constructor(string _name) ERC20(_name) public { //继承ERC20合约的构造函数
    }

    event AddSupply(uint amount); //定义增发事件
    event FrozenFunds(address indexed target, bool frozen); //定义冻结（解冻）事件
    event Burn(address indexed target, uint256 amount); //定义销毁代币事件

    //通过定义一个挖矿函数，实现代币的增发，该函数要求只有代币管理者才能挖矿（调用），并指定增发对象和数量
    function mine(address _target, uint256 _amount) public onlyOwner { //函数修改器规定了权限

        require(_target != address(0)); //目标账号为空判断
        require(balanceOf[_target] + _amount >= balanceOf[_target]); //转账溢出判断

        balanceOf[_target] += _amount; //增发
        totalSupply += _amount; //修改总发行量

        emit Transfer(0, _target, _amount); //挖矿相当于一个转出账户为0的转账，所以出发转账事件
        emit AddSupply(_amount); //触发增发事件
    }

    //定义冻结（解冻）账户的函数
    function freezeAccount(address _target, bool _frozen) public onlyOwner { //只有代币管理者可以更改冻结状态
        
        frozenAccount[_target] = _frozen; //改变状态
        emit FrozenFunds(_target, _frozen); //触发事件
    }

    //重载基类ERC20的转账方法，增加账户冻结判断
    function transfer(address _to, uint256 _value) public returns(bool success) {

        success = _transfer(msg.sender, _to, _value);
    }

    //重载基类ERC20的授权后转账方法，增加账户冻结判断
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {

        require(allowed[_from][msg.sender] >= _value); //既检查调用者是否是被委托者，又检查被授权的金额是否足够转账
        success = _transfer(_from, _to, _value);
        allowed[_from][msg.sender] -= _value; //被授权的额度也要减少
    }

    //定义一个内部函数 优化上面两个转账函数 将共同部分抽离出来
    function _transfer(address _from, address _to, uint256 _value) internal returns(bool) {
        
        require(_to != address(0)); //目标账号为空判断
        require(!frozenAccount[_from]); //转出账户冻结判断
        require(balanceOf[_from] >= _value); //余额充足判断
        require(balanceOf[_to] + _value >= balanceOf[_to]); //转账溢出判断

        balanceOf[_from] -= _value; //付款账号减
        balanceOf[_to] += _value; //接收账号加

        emit Transfer(_from, _to, _value); //触发事件，添加日志
        return true;
    }

    //代币销毁函数
    function burn(uint256 _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value); //账户余额是否足够判断

        totalSupply -= _value; //总供应量减少
        balanceOf[msg.sender] -= _value; //账户余额减少

        emit Burn(msg.sender, _value); //触发销毁事件，记录日志
        success = true; //销毁成功 返回true
    }

    //授权后的代币销毁函数
    function burnFrom(address _from, uint256 _value) public returns(bool success) {

        require(balanceOf[_from] >= _value); //委托者账户余额是否足够判断
        require(allowed[_from][msg.sender] >= _value); //既检查调用者是否为被委托者，又判断授权余额是否足够销毁

        totalSupply -= _value; //总供应量减少
        //balanceOf[msg.sender] -= _value; //账户余额减少
        balanceOf[_from] -= _value; //账户余额减少
        allowed[_from][msg.sender] -= _value; //被授权管理的资金相应减少

        emit Burn(msg.sender, _value); //触发销毁事件，记录日志
        success = true; //销毁成功 返回true
    }
}
