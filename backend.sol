// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() public view virtual returns (uint256) {}
    function balanceOf(address _owner) public view virtual returns (uint256) {}
    function transfer(address _to, uint256 _value) public virtual returns (bool) {}
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {}
    function approve(address _spender, uint256 _value) public virtual returns (bool) {}
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {}
}

contract StandardToken is Token {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal _totalSupply; // Renamed the variable to avoid conflict

    function totalSupply() public view override returns (uint256) {
        return _totalSupply; // Return the internal variable
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(balances[msg.sender] >= _value && _value > 0, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or allowance");
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowed[_owner][_spender];
    }
}

contract BethTestToken is StandardToken {
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;         
    address payable public fundsWallet;    

    constructor() {
        name = "NUGGET TRAP";
        decimals = 8;
        symbol = "NGT";
        unitsOneEthCanBuy = 3940;
        fundsWallet = payable(msg.sender);  

        uint256 initialSupply = 1000 * (10 ** uint256(decimals)); 
        balances[msg.sender] = initialSupply; 
        _totalSupply = initialSupply; // Set the internal total supply variable
    }

    receive() external payable {
        totalEthInWei += msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;

        require(balances[fundsWallet] >= amount, "Not enough tokens available");

        balances[fundsWallet] -= amount;
        balances[msg.sender] += amount;

        emit Transfer(fundsWallet, msg.sender, amount);
        
        // Use call to transfer Ether
        (bool success, ) = fundsWallet.call{value: msg.value}("");
        require(success, "Transfer failed"); 
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        (bool success, ) = _spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", msg.sender, _value, address(this), _extraData));
        require(success, "Call failed");
        return true;
    }
}
