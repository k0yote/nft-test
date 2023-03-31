// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IOperable {
    event RoleGranted(address indexed account, address indexed sender);
    event RoleRevoked(address indexed account, address indexed sender);

    function isOperator(address account) external view returns (bool);
}
