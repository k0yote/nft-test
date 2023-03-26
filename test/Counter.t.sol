// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import { Test, stdError } from "forge-std/Test.sol";
import { Counter } from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function testCount() public {
        assertEq(counter.get(), 0);
    }

    function testInc() public {
        counter.inc();
        assertEq(counter.count(), 1);
    }

    function testFailDec() public {
        counter.dec();
    }

    function testDecUnderFlow() public {
        vm.expectRevert(stdError.arithmeticError);
        counter.dec();
    }
}
