// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ArcPayAgent} from "../src/ArcPayAgent.sol";

contract MockUSDC {
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

contract ArcPayAgentTest is Test {
    ArcPayAgent agent;
    MockUSDC usdc;

    address owner = address(0x1);
    address recipient = address(0x2);

    function setUp() public {
        usdc = new MockUSDC();

        vm.prank(owner);
        agent = new ArcPayAgent(address(usdc));

        usdc.mint(address(agent), 1_000_000);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(agent.owner(), owner);
    }

    function testUSDCAddressIsCorrect() public view {
        assertEq(address(agent.usdc()), address(usdc));
    }

    function testInitialBalance() public view {
        assertEq(agent.getBalance(), 1_000_000);
    }

    function testExecutePayment() public {
        vm.prank(owner);

        agent.executePayment(recipient, 100_000, "Test payment");

        assertEq(usdc.balanceOf(recipient), 100_000);
        assertEq(agent.getBalance(), 900_000);
    }

    function testExecutePaymentEmitsEvent() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true);

        emit ArcPayAgent.PaymentExecuted(recipient, 100_000, "Test payment");

        agent.executePayment(recipient, 100_000, "Test payment");
    }

    function testRebalanceWhenThresholdReached() public {
        vm.prank(owner);

        agent.checkAndRebalance(recipient, 500_000, 100_000);

        assertEq(usdc.balanceOf(recipient), 100_000);
        assertEq(agent.getBalance(), 900_000);
    }

    function testRebalanceEmitsEvent() public {
        vm.prank(owner);

        vm.expectEmit(false, false, false, true);

        emit ArcPayAgent.RuleTriggered("rebalance", 100_000);

        agent.checkAndRebalance(recipient, 500_000, 100_000);
    }

    function testRebalanceDoesNothingBelowThreshold() public {
        vm.prank(owner);

        agent.checkAndRebalance(recipient, 2_000_000, 100_000);

        assertEq(usdc.balanceOf(recipient), 0);
        assertEq(agent.getBalance(), 1_000_000);
    }

    function testOnlyOwnerCanExecutePayment() public {
        address attacker = address(0x3);

        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.executePayment(recipient, 100_000, "Unauthorized");
    }

    function testOnlyOwnerCanRebalance() public {
        address attacker = address(0x3);

        vm.prank(attacker);

        vm.expectRevert("Not owner");

        agent.checkAndRebalance(recipient, 500_000, 100_000);
    }

    function testTransferOwnership() public {
        address newOwner = address(0x4);

        vm.prank(owner);

        agent.transferOwnership(newOwner);

        assertEq(agent.owner(), newOwner);
    }
}
