// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ArcPayAgent {
    address public owner;
    IERC20 public immutable usdc;

    event PaymentExecuted(address indexed to, uint256 amount, string reason);
    event RuleTriggered(string ruleName, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _usdc) {
        owner = msg.sender;
        usdc = IERC20(_usdc);
    }

    // Manuel ödeme
    function executePayment(address to, uint256 amount, string calldata reason) external onlyOwner {
        require(usdc.balanceOf(address(this)) >= amount, "Insufficient USDC");
        require(usdc.transfer(to, amount), "Transfer failed");
        emit PaymentExecuted(to, amount, reason);
    }

    // Otomatik rebalance rule (threshold üstündeyse gönder)
    function checkAndRebalance(address target, uint256 threshold, uint256 sendAmount) external onlyOwner {
        uint256 bal = usdc.balanceOf(address(this));
        if (bal >= threshold) {
            require(usdc.transfer(target, sendAmount), "Rebalance failed");
            emit RuleTriggered("rebalance", sendAmount);
            emit PaymentExecuted(target, sendAmount, "Auto rebalance");
        }
    }

    // Contract bakiyesini gör
    function getBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    // Ownership transfer
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
