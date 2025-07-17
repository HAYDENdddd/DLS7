// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// 接收回调合约需要实现这个接口
interface ITokenReceiver {
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract BaseERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10**uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        uint256 currentAllowance = allowances[_from][msg.sender];
        require(balances[_from] >= _value, "ERC20: insufficient balance");
        require(currentAllowance >= _value, "ERC20: insufficient allowance");

        allowances[_from][msg.sender] = currentAllowance - _value;
        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    /// ✅ 加入新的 transferWithCallback 函数
    function transferWithCallback(
        address to,
        uint256 amount,
        bytes calldata data
    ) public returns (bool) {
        _transfer(msg.sender, to, amount);

        if (isContract(to)) {
            ITokenReceiver(to).tokensReceived(msg.sender, amount, data);
        }

        return true;
    }

    /// ✅ 实现内部 _transfer 逻辑，供多个函数复用
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(balances[from] >= amount, "ERC20: transfer exceeds balance");

        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// ✅ 判断一个地址是否是合约
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
