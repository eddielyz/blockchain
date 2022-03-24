pragma solidity ^0.4.24;

//众筹合约，通过本合约实现众筹，需要与一个代币向关联

//代币众筹 演示流程：
// 1.部署代币合约，使用同目录下的AdvanceToken合约，它继承了ERC20标准合约和代币管理者合约Owned
//   合约部署账号是 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 即代币管理者
//   部署后的合约地址是 0x0813d4a158d06784FDB48323344896B2B1aa0F85
// 2.切换一个新的环境账号，用来部署众筹合约ICO，该账号将作为众筹受益人 0xdD870fA1b7C4700F2BD7f44238821C26f7392148
//   部署时需要填入的参数，众筹目标30个以太币、众筹时间10分钟、兑换价格1:1每个以太价值1个代币、代币地址填入上面的代币合约地址0x9a...
//   部署后的合约地址是 0xa256116B8A38F0D716e973322bff7288c2F36531
// 3.目前众筹合约内无任何代币及以太币，在测试众筹打币之前，需先给众筹合约一定数量代币，用于再接收到募集的以太币时，返回给捐助者
//   切换至代币管理者账户，通过代币合约的transfer函数，向众筹合约打入50个代币
// 4.切换一个新的环境账号，其角色为众筹的捐助人 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7
//   通过该捐助人账号 向众筹合约发起捐助过程，使回退函数被自动调用，但该转账过程无法模拟，因此我们定义了一个fallback2函数，
//   其内容与回退函数相同，来模拟转账过程。注意，调用fallback2函数时，需要携带捐助数量的以太币，value 23，单位ether
// 5.至此，众筹合约的fallback2函数被调用一次，就完成了一次投资捐助，我们可以用捐助人账号地址查看其投资余额
// 6.且该投资者账户中应该已转入1:1比例的代币，我们在代币合约中，使用投资者账户地址查看其代币余额
// 7.一个简单的众筹过程测试完成，另外众筹时间结束、退款、受益人提款等，可做进一步测试

import "./owned.sol";

//定义一个接口，要求必须实现一个transfer方法，用于交换代币与以太币
interface token {
    function transfer(address _to, uint256 _amount) external;
}

//众筹合约
contract ICO is Owned{
    
    uint public fundingGoal; //众筹目标 以ether为单位
    uint public endLine; //众筹结束时间 以minutes为单位
    uint public price; //兑换价格 一个ether换多少个代币
    address public beneficiary; //受益人地址
    uint public fundAmount; //当前已募集到的金额
    token public tokenReward; //关联的token合约

    mapping(address => uint256) public balanceOf; //每个用户已经众筹的以太币数，相当于用户在该合约中的余额

    event FundTransfer(address indexed backer, uint256 amount); //定义一个事件，用来保存每次募捐

    //构造函数
    constructor(
        uint fundingGoalInEthers, 
        uint durationInMinutes, 
        uint etherCostOfEachToken,
        token addressOfToken) public {
            
            fundingGoal = fundingGoalInEthers * 1 ether; //以以太币计价
            endLine = now + durationInMinutes * 1 minutes; //用minutes为单位，计算从众筹开始+众筹时间 = 结束时间
            price = etherCostOfEachToken * 1 ether; //打过来的以太币是以wei为单位 1 ether = 10**18wei
            beneficiary = msg.sender; //受益人默认为合约创建者，也可以用参数传进来
            tokenReward = token(address(addressOfToken)); //强制转换，把地址转换为合约类型
    }

    //回退函数 利用“合约收到代币时，回退函数会自动触发”的特性 注意payable修饰
    function () public payable {

        require(now < endLine); //判断当前时间是否在众筹期内

        uint amount = msg.value; //获得打过来的以太币，以wei为单位
        
        balanceOf[msg.sender] += amount; //记账，记录众筹数据
        fundAmount += amount; //记录已募集的金额

        //众筹过程允许“空投”时
        uint tokenAmount = 0;
        if(amount == 0){
            tokenAmount = 10; //空投情况给10个代币
        }
        else{
            tokenAmount = amount / price; //用兑换价格计算应返回的代币数
        }
        
        tokenReward.transfer(msg.sender, tokenAmount); //将代币打回去

        emit FundTransfer(msg.sender, amount); //触发事件记录日志
    }

    //模拟回退函数的函数 用于在remix环境中 测试该合约被转账 
    function fallback2() public payable { 
        require(now < endLine); //判断当前时间是否在众筹期内

        uint amount = msg.value; //获得打过来的以太币，以wei为单位
        //emit Fund(amount);
        balanceOf[msg.sender] += amount; //记账，记录众筹数据
        fundAmount += amount; //记录已募集的金额

        uint tokenAmount = amount / price; //用兑换价格计算应返回的代币数
        tokenReward.transfer(msg.sender, tokenAmount); //将代币打回去

        emit FundTransfer(msg.sender, amount); //触发事件记录日志
    }

    //定义提款函数
    function withdrawal() public {

        require(now >= endLine); //判断众筹是否已结束
        if(fundAmount >= fundingGoal){ //如果募集总额已达标
            if(beneficiary == msg.sender){
                beneficiary.transfer(fundAmount); //受益人转走全部募集资金
            }   
        }
        else{ //如果募集金额未达标，则调用者通过此函数 退款
            uint amount = balanceOf[msg.sender];
            if(amount > 0){
                msg.sender.transfer(amount); //退款
                balanceOf[msg.sender] = 0; //退款后，清空该捐助人的余额
            }
        }
    }

    //定义支持阶梯价格的函数
    function setPrice(uint etherCostOfEachToken) public onlyOwner { //onlyOwner修饰器，只有代币管理者可以调用此函数

        //该函数可随已众筹到的金额数变化而随时被调用，调用后变更兑换价格，实现不同的阶梯价位
        price = etherCostOfEachToken; //设置价格
    }
}
