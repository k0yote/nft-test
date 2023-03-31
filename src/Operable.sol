// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { IOperable } from "./interfaces/IOperable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

error SoulBoundTokenOnlyOperator(address);

abstract contract Operable is Context, IOperable {
    mapping(address => bool) _operators;

    modifier onlyOperatorRole() {
        _checkOperatorRole(_msgSender());
        _;
    }

    function isOperator(address _operator) public view virtual override returns (bool) {
        return _operators[_operator];
    }

    function _grantOperatorRole(address _candidate) internal virtual {
        if (!isOperator(_candidate)) {
            _operators[_candidate] = true;
            emit RoleGranted(_candidate, _msgSender());
        }
    }

    function _revokeOperatorRole(address _candidate) internal virtual {
        if (isOperator(_candidate)) {
            delete _operators[_candidate];
            emit RoleRevoked(_candidate, _msgSender());
        }
    }

    function _checkOperatorRole(address _operator) internal view virtual {
        if (!isOperator(_operator)) {
            revert SoulBoundTokenOnlyOperator(_operator);
        }
    }
}
