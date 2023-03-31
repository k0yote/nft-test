// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC5192 } from "../src/interfaces/IERC5192.sol";
import { ERC5192 } from "../src/ERC5192.sol";

contract MinimalSoulBoundToken is ERC5192 {
    constructor(string memory _name, string memory _symbol, bool _isLocked) ERC5192(_name, _symbol, _isLocked) { }
}

contract ERC5192Test is Test, ERC721Holder {
    MinimalSoulBoundToken lockedToken;
    MinimalSoulBoundToken unlockedToken;
    address deployer = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address to = address(1);
    address receiver1 = address(2);
    address receiver2 = address(3);
    address prank = address(4);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        string memory name = "Name";
        string memory symbol = "Symbol";
        lockedToken = new MinimalSoulBoundToken(name, symbol, true);
        unlockedToken = new MinimalSoulBoundToken(name, symbol, false);
    }

    function testIERC721() public {
        assertTrue(lockedToken.supportsInterface(type(IERC721).interfaceId));
    }

    function testIERC165() public {
        assertTrue(lockedToken.supportsInterface(type(IERC165).interfaceId));
    }

    function testIERC721Metadata() public {
        assertTrue(lockedToken.supportsInterface(type(IERC721Metadata).interfaceId));
    }

    function testIERC5192() public {
        bytes4 interfaceId = type(IERC5192).interfaceId;
        assertEq(interfaceId, bytes4(0xb45a3c0e));
        assertTrue(lockedToken.supportsInterface(interfaceId));
        assertTrue(unlockedToken.supportsInterface(interfaceId));
    }

    function testCallingLockedOnUnlocked() public {
        uint256 tokenId = 0;
        unlockedToken.mint(to, tokenId);
        assertFalse(unlockedToken.locked(tokenId));
    }

    function testCallingLockedOnLocked() public {
        uint256 tokenId = 0;
        lockedToken.mint(to, tokenId);
        assertTrue(lockedToken.locked(tokenId));
    }

    function testLockedThrowingOnNonExistentTokenId() public {
        vm.expectRevert("ERC721: invalid token ID");
        lockedToken.locked(1337);

        vm.expectRevert("ERC721: invalid token ID");
        unlockedToken.locked(1337);
    }

    function testEnabledSafeTransferFromWithData() public {
        uint256 tokenId = 0;
        unlockedToken.mint(deployer, tokenId);

        bytes memory data;
        unlockedToken.safeTransferFrom(deployer, receiver1, tokenId, data);
        assertEq(unlockedToken.ownerOf(tokenId), receiver1);
    }

    function testEnabledSafeTransferFrom() public {
        uint256 tokenId = 0;
        unlockedToken.mint(deployer, tokenId);

        unlockedToken.safeTransferFrom(deployer, receiver1, tokenId);
        assertEq(unlockedToken.ownerOf(tokenId), receiver1);
    }

    function testBlockedSafeTransferFrom() public {
        uint256 tokenId = 0;
        lockedToken.mint(to, tokenId);

        bytes memory data;
        vm.expectRevert(ERC5192.ErrLocked.selector);
        vm.startPrank(prank, prank);
        lockedToken.safeTransferFrom(to, receiver1, tokenId, data);

        vm.expectRevert(ERC5192.ErrLocked.selector);
        lockedToken.safeTransferFrom(to, receiver1, tokenId);
        vm.stopPrank();
    }

    function testSafeTransferFromByMinterRole() public {
        uint256 tokenId = 0;
        lockedToken.mint(to, tokenId);

        bytes memory data;
        lockedToken.safeTransferFrom(to, receiver1, tokenId);
        assertEq(lockedToken.ownerOf(tokenId), receiver1);
        lockedToken.safeTransferFrom(receiver1, receiver2, tokenId, data);
        assertEq(lockedToken.ownerOf(tokenId), receiver2);
    }

    function testEnabledTransferFrom() public {
        uint256 tokenId = 0;
        unlockedToken.mint(deployer, tokenId);
        unlockedToken.transferFrom(address(this), receiver1, tokenId);
        assertEq(unlockedToken.ownerOf(tokenId), receiver1);
    }

    function testBlockedTransferFromByNotMinterRole() public {
        uint256 tokenId = 0;
        lockedToken.mint(deployer, tokenId);
        vm.startPrank(prank, prank);
        vm.expectRevert(ERC5192.ErrLocked.selector);
        lockedToken.transferFrom(address(this), address(1), tokenId);
        vm.stopPrank();
    }

    function testEnabledApprove() public {
        uint256 tokenId = 0;
        unlockedToken.mint(deployer, tokenId);

        unlockedToken.approve(receiver1, tokenId);
        assertEq(unlockedToken.getApproved(tokenId), receiver1);
    }

    function testBlockedApprove() public {
        uint256 tokenId = 0;
        lockedToken.mint(deployer, tokenId);

        vm.startPrank(prank, prank);
        vm.expectRevert(ERC5192.ErrLocked.selector);
        lockedToken.approve(address(1), tokenId);
        vm.stopPrank();
    }

    function testEnabledSetApproveForAll() public {
        uint256 tokenId = 0;
        unlockedToken.mint(deployer, tokenId);

        unlockedToken.setApprovalForAll(to, true);
        assertEq(unlockedToken.isApprovedForAll(deployer, to), true);
    }

    function testBlockedSetApprovalForAll() public {
        vm.startPrank(prank, prank);
        vm.expectRevert(ERC5192.ErrLocked.selector);
        lockedToken.setApprovalForAll(to, true);
        vm.stopPrank();
    }
}
