// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ArcPayAgentV2} from "../src/ArcPayAgentV2.sol";

contract MockUSDCV2 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    function decimals() external pure returns (uint8) {
        return 6;
    }
}

contract ArcPayAgentV2Test is Test {
    ArcPayAgentV2 agent;
    MockUSDCV2 usdc;

    address owner = address(0x1);
    address recipient = address(0x2);
    address attacker = address(0x3);

    uint256 constant INITIAL_BALANCE = 1_000_000;
    uint256 constant THRESHOLD = 500_000;
    uint256 constant PAYMENT = 100_000;

    function setUp() public {
        usdc = new MockUSDCV2();

        vm.prank(owner);
        agent = new ArcPayAgentV2(address(usdc));

        usdc.mint(address(agent), INITIAL_BALANCE);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(agent.owner(), owner);
    }

    function testUSDCAddressIsCorrect() public view {
        assertEq(address(agent.usdc()), address(usdc));
    }

    function testInitialBalance() public view {
        assertEq(agent.getBalance(), INITIAL_BALANCE);
    }

    function testCreateRule() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        assertEq(ruleId, 0);

        (address target, uint256 threshold, uint256 amount, bool active) = agent.getRule(ruleId);

        assertEq(target, recipient);
        assertEq(threshold, THRESHOLD);
        assertEq(amount, PAYMENT);
        assertTrue(active);
    }

    function testRuleIdsIncrement() public {
        vm.startPrank(owner);

        uint256 firstRule = agent.createRule(recipient, THRESHOLD, PAYMENT);

        uint256 secondRule = agent.createRule(recipient, 700_000, 200_000);

        vm.stopPrank();

        assertEq(firstRule, 0);
        assertEq(secondRule, 1);
        assertEq(agent.nextRuleId(), 2);
    }

    function testCreateRuleEmitsEvent() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true);

        emit ArcPayAgentV2.RuleCreated(0, recipient, THRESHOLD, PAYMENT);

        agent.createRule(recipient, THRESHOLD, PAYMENT);
    }

    function testCreateRuleRejectsZeroAddress() public {
        vm.prank(owner);

        vm.expectRevert("Invalid target");

        agent.createRule(address(0), THRESHOLD, PAYMENT);
    }

    function testCreateRuleRejectsZeroThreshold() public {
        vm.prank(owner);

        vm.expectRevert("Invalid threshold");

        agent.createRule(recipient, 0, PAYMENT);
    }

    function testCreateRuleRejectsZeroAmount() public {
        vm.prank(owner);

        vm.expectRevert("Invalid amount");

        agent.createRule(recipient, THRESHOLD, 0);
    }

    function testOnlyOwnerCanCreateRule() public {
        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.createRule(recipient, THRESHOLD, PAYMENT);
    }

    function testExecuteRuleFailsBelowThreshold() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, 2_000_000, PAYMENT);

        vm.prank(owner);

        vm.expectRevert("Threshold not reached");

        agent.executeRule(ruleId);
    }

    function testExecuteRuleTransfersPayment() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        agent.executeRule(ruleId);

        assertEq(usdc.balanceOf(recipient), PAYMENT);
        assertEq(agent.getBalance(), INITIAL_BALANCE - PAYMENT);
    }

    function testExecuteRuleEmitsEvents() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        vm.expectEmit(true, true, true, true);

        emit ArcPayAgentV2.RuleExecuted(ruleId, recipient, PAYMENT);

        agent.executeRule(ruleId);
    }

    function testOnlyOwnerCanExecuteRule() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.executeRule(ruleId);
    }

    function testDeactivateRule() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        agent.deactivateRule(ruleId);

        (,,, bool active) = agent.getRule(ruleId);

        assertFalse(active);
    }

    function testDeactivateRuleEmitsEvent() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        vm.expectEmit(true, false, false, true);

        emit ArcPayAgentV2.RuleDeactivated(ruleId);

        agent.deactivateRule(ruleId);
    }

    function testDeactivatedRuleCannotExecute() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        agent.deactivateRule(ruleId);

        vm.prank(owner);

        vm.expectRevert("Rule inactive");

        agent.executeRule(ruleId);
    }

    function testOnlyOwnerCanDeactivateRule() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.deactivateRule(ruleId);
    }

    function testTransferOwnership() public {
        address newOwner = address(0x4);

        vm.prank(owner);

        agent.transferOwnership(newOwner);

        assertEq(agent.owner(), newOwner);
    }

    function testCannotTransferOwnershipToZeroAddress() public {
        vm.prank(owner);

        vm.expectRevert("Invalid owner");

        agent.transferOwnership(address(0));
    }
}
