// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract ArcPayAgentV3 {
    IERC20 public immutable usdc;
    address public owner;
    address public agent;

    struct PaymentRule {
        address target;
        uint256 threshold;
        uint256 amount;
        bool active;
        uint256 maxExecutions;
        uint256 executionCount;
        uint256 cooldown;
        uint256 lastExecutedAt;
    }

    uint256 public nextRuleId;

    mapping(uint256 => PaymentRule) public rules;

    event PaymentExecuted(
        address indexed to,
        uint256 amount,
        string reason
    );

    event RuleCreated(
        uint256 indexed ruleId,
        address indexed target,
        uint256 threshold,
        uint256 amount
    );

    event RuleExecuted(
        uint256 indexed ruleId,
        address indexed target,
        uint256 amount
    );

    event RuleDeactivated(uint256 indexed ruleId);
        event AgentUpdated(
        address indexed oldAgent,
        address indexed newAgent
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _usdc) {
        owner = msg.sender;
        usdc = IERC20(_usdc);
    
    }

    function setAgent(address _agent) external onlyOwner {
        require(_agent != address(0), "Invalid agent");

        address oldAgent = agent;
        agent = _agent;

        emit AgentUpdated(oldAgent, _agent);
    }

    function createRule(
        address target,
        uint256 threshold,
        uint256 amount
    ) external onlyOwner returns (uint256 ruleId) {
        require(target != address(0), "Invalid target");
        require(threshold > 0, "Invalid threshold");
        require(amount > 0, "Invalid amount");

        ruleId = nextRuleId++;

        rules[ruleId] = PaymentRule({
            target: target,
            threshold: threshold,
            amount: amount,
            active: true,
            maxExecutions: 0,
            executionCount: 0,
            cooldown: 0,
            lastExecutedAt: 0
        });

        emit RuleCreated(
            ruleId,
            target,
            threshold,
            amount
        );
    }

    function executeRule(uint256 ruleId) external {
        require(
            msg.sender == owner || msg.sender == agent,
            "Not authorized executor"
        );

        PaymentRule storage rule = rules[ruleId];

        require(rule.active, "Rule inactive");
        require(
            usdc.balanceOf(address(this)) >= rule.threshold,
            "Threshold not reached"
        );
        require(
            usdc.balanceOf(address(this)) >= rule.amount,
            "Insufficient balance"
        );

        require(
            usdc.transfer(rule.target, rule.amount),
            "USDC transfer failed"
        );

        emit PaymentExecuted(
            rule.target,
            rule.amount,
            "Rule payment"
        );

        emit RuleExecuted(
            ruleId,
            rule.target,
            rule.amount
        );
    }

    function deactivateRule(uint256 ruleId) external onlyOwner {
        PaymentRule storage rule = rules[ruleId];

        require(rule.active, "Rule inactive");

        rule.active = false;

        emit RuleDeactivated(ruleId);
    }

    function getRule(uint256 ruleId)
        external
        view
        returns (
            address target,
            uint256 threshold,
            uint256 amount,
            bool active
        )
    {
        PaymentRule memory rule = rules[ruleId];

        return (
            rule.target,
            rule.threshold,
            rule.amount,
            rule.active
        );
    }

    function getBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");

        owner = newOwner;
    }
}
