// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ArcPayAgentV3} from "../src/ArcPayAgentV3.sol";

contract MockUSDCV3 {
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

contract ArcPayAgentV3Test is Test {
    ArcPayAgentV3 agent;
    MockUSDCV3 usdc;

    address owner = address(0x1);
    address recipient = address(0x2);
    address attacker = address(0x3);
    address automationAgent = address(0x4);

    uint256 constant INITIAL_BALANCE = 1_000_000;
    uint256 constant THRESHOLD = 500_000;
    uint256 constant PAYMENT = 100_000;

    function setUp() public {
        usdc = new MockUSDCV3();

        vm.prank(owner);
        agent = new ArcPayAgentV3(address(usdc));

        usdc.mint(address(agent), INITIAL_BALANCE);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(agent.owner(), owner);
    }

    function testAgentInitiallyZero() public view {
        assertEq(agent.agent(), address(0));
    }

    function testSetAgent() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        assertEq(agent.agent(), automationAgent);
    }

    function testSetAgentEmitsEvent() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);

        emit ArcPayAgentV3.AgentUpdated(address(0), automationAgent);

        agent.setAgent(automationAgent);
    }

    function testOnlyOwnerCanSetAgent() public {
        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.setAgent(automationAgent);
    }

    function testCannotSetZeroAgent() public {
        vm.prank(owner);

        vm.expectRevert("Invalid agent");

        agent.setAgent(address(0));
    }

    function testOwnerCanExecuteRule() public {
        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        agent.executeRule(ruleId);

        assertEq(usdc.balanceOf(recipient), PAYMENT);
    }

    function testAuthorizedAgentCanExecuteRule() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(automationAgent);

        agent.executeRule(ruleId);

        assertEq(usdc.balanceOf(recipient), PAYMENT);
    }

    function testUnauthorizedAddressCannotExecuteRule() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(attacker);

        vm.expectRevert("Not authorized executor");

        agent.executeRule(ruleId);
    }

    function testAgentCannotCreateRule() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(automationAgent);

        vm.expectRevert("Not owner");

        agent.createRule(recipient, THRESHOLD, PAYMENT);
    }

    function testAgentCannotDeactivateRule() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(automationAgent);

        vm.expectRevert("Not owner");

        agent.deactivateRule(ruleId);
    }

    function testAgentCannotChangeAgent() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(automationAgent);

        vm.expectRevert("Not owner");

        agent.setAgent(attacker);
    }

    function testAgentCannotExecuteBelowThreshold() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, 2_000_000, PAYMENT);

        vm.prank(automationAgent);

        vm.expectRevert("Threshold not reached");

        agent.executeRule(ruleId);
    }

    function testDeactivatedRuleCannotBeExecutedByAgent() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(owner);

        agent.deactivateRule(ruleId);

        vm.prank(automationAgent);

        vm.expectRevert("Rule inactive");

        agent.executeRule(ruleId);
    }

    function testAgentCanExecuteMultipleTimes() public {
        vm.prank(owner);

        agent.setAgent(automationAgent);

        vm.prank(owner);

        uint256 ruleId = agent.createRule(recipient, THRESHOLD, PAYMENT);

        vm.prank(automationAgent);
        agent.executeRule(ruleId);

        vm.prank(automationAgent);
        agent.executeRule(ruleId);

        assertEq(usdc.balanceOf(recipient), PAYMENT * 2);
    }

    function testTransferOwnership() public {
        address newOwner = address(0x5);

        vm.prank(owner);

        agent.transferOwnership(newOwner);

        assertEq(agent.owner(), newOwner);
    }
}
