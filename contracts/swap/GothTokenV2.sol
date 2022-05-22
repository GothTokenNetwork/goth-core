// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../utils/Context.sol";
import "../utils/Ownable.sol";
import "../utils/SafeMath.sol";
import "../utils/ReentrancyGuard.sol";
import "../erc20/IERC20.sol";
import "../erc20/IERC20Metadata.sol";

contract GothTokenV2 is Ownable, IERC20, IERC20Metadata, ReentrancyGuard 
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxSupply = 1_000_000_000e18;

    string private _name;
    string private _symbol;

    IERC20 public immutable GOTHV1;
    uint256 private swapPeriodEnd;

    event SwapOldGOTH(address account, uint256 oldGothBurnt, uint256 newGothMinted);

    constructor(IERC20 _gothV1) 
    {
        _name = "GOTH Token v2";
        _symbol = "GOTH";
        GOTHV1 = _gothV1;
        swapPeriodEnd = block.timestamp + 31_540_000;
        _mint(msg.sender, 100_000_000e18);
    }

    function name() public view virtual override returns (string memory) 
    {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) 
    {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) 
    {
        return _totalSupply;
    }

    function maxSupply() public view virtual returns (uint256) 
    {
        return _maxSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) 
    {
        return _balances[account];
    }

    function swapOldGOTH (uint256 amount) external nonReentrant
    {
        require(GOTHV1.balanceOf(msg.sender) >= amount, "swapOldGOTH: not enough old GOTH");
        require(block.timestamp < swapPeriodEnd, "swapOldGOTH: the time window for swapping old GOTH to GOTH v2 has ended");
        
        GOTHV1.transferFrom(msg.sender, address(1), amount);


        uint256 newAmount = amount.add(amount.div(10)).div(1000);
        _mint(msg.sender, newAmount);

        emit SwapOldGOTH(msg.sender, amount, newAmount);
    } 

    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function burn(uint256 amount) public virtual returns (bool)
    {
        _burn(_msgSender(), amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked 
        {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked 
        {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked 
        {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function mint (address account, uint256 amount) public onlyOwner returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_maxSupply.sub(_totalSupply) >= amount, "ERC20: max supply reached");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual 
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked 
        {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}