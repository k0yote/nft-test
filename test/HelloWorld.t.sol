// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { HelloWorld } from "../src/HelloWorld.sol";

contract HelloWorldTest is PRBTest {
    HelloWorld public helloWorld;

    function setUp() public {
        helloWorld = new HelloWorld();
    }

    function testGreet() public {
        assertEq(helloWorld.greet(), "Hello World!");
    }
}
