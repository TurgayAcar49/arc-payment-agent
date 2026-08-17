// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ArcPayAgent} from "../src/ArcPayAgent.sol";

contract DeployArcPayAgent is Script {
    address constant USDC = 0x3600000000000000000000000000000000000000;

    function run() external returns (ArcPayAgent agent) {
        vm.startBroadcast();

        agent = new ArcPayAgent(USDC);

        vm.stopBroadcast();
    }
}
