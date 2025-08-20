// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Erc20Token {
    // 代币名称
    string public name = "Erc20 Token";
    // 代币符号
    string public symbol = "TEST";

    // 代币小数位数
    uint8 public decimals = 6;

    // 代币总供应量，初始值在构造函数中设置
    uint256 public totalSupply;

    // 记录每个地址持有的代币数量
    mapping(address => uint256) public balanceOf;

    // 记录授权关系，即地址A允许地址B使用的代币数量
    mapping(address => mapping(address => uint256)) public allowance;

    // 合约所有者地址，拥有铸造代币的权限
    address public owner;

    // 当代币转移时触发，记录发送方、接收方和金额
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 当授权发生变化时触发，记录授权方、被授权方和金额
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 当新代币被铸造时触发，记录接收方和金额
    event Mint(address indexed to, uint256 value);

    // 限制只有合约所有者才能调用被修饰的函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint256 _initialSupply) {
        // 设置合约部署者为所有者
        owner = msg.sender;

        // 计算初始总供应量（考虑小数位数）
        totalSupply = _initialSupply;

        // 将所有初始代币分配给合约部署者
        balanceOf[msg.sender] = totalSupply;

        // 发出代币创建的转账事件（从零地址转到部署者）
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // 检查发送者余额是否足够
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        // 检查接收地址是否有效（不是零地址）
        require(_to != address(0), "Invalid address");

        // 从发送者余额中减去转账金额
        balanceOf[msg.sender] -= _value;

        // 向接收者余额中添加转账金额
        balanceOf[_to] += _value;

        // 发出转账事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        // 设置调用者允许指定地址使用的代币数量
        allowance[msg.sender][_spender] = _value;

        // 发出授权事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // 检查源地址余额是否足够
        require(balanceOf[_from] >= _value, "Insufficient balance");
        // 检查调用者是否有足够的授权额度
        require(
            allowance[_from][msg.sender] >= _value,
            "Insufficient allowance"
        );
        // 检查接收地址是否有效
        require(_to != address(0), "Invalid address");

        // 从源地址余额中减去转账金额
        balanceOf[_from] -= _value;

        // 向接收地址余额中添加转账金额
        balanceOf[_to] += _value;

        // 减少调用者的授权额度
        allowance[_from][msg.sender] -= _value;

        // 发出转账事件
        emit Transfer(_from, _to, _value);

        return true;
    }

    function mint(
        address _to,
        uint256 _value
    ) public onlyOwner returns (bool success) {
        require(_to != address(0), "Invalid address");

        // 增加总供应量
        totalSupply += _value;

        // 增加接收地址的余额
        balanceOf[_to] += _value;

        // 发出铸造事件
        emit Mint(_to, _value);

        // 发出从零地址到接收地址的转账事件（表示新代币的创建）
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        // 检查调用者余额是否足够
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        // 减少调用者的余额
        balanceOf[msg.sender] -= _value;

        // 减少总供应量
        totalSupply -= _value;

        // 发出从调用者到零地址的转账事件（表示代币的销毁）
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}
