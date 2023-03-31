// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { IERC5192 } from "./interfaces/IERC5192.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

abstract contract ERC5192 is ERC721, ERC721URIStorage, Ownable, AccessControl, IERC5192 {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool private _isLocked;
    string private baseURI;

    error ErrLocked();

    constructor(string memory name, string memory symbol, bool isLocked) ERC721(name, symbol) {
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setupRole(MINTER_ROLE, _msgSender());
        _isLocked = isLocked;
    }

    modifier checkLock() {
        if (_isLocked && !hasRole(MINTER_ROLE, _msgSender())) revert ErrLocked();
        _;
    }

    function mint(address to, uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721Mintble: must have minter role to mint");
        _mint(to, tokenId);
        if (_isLocked) {
            super._approve(_msgSender(), tokenId);
            emit Locked(tokenId);
        }
    }

    function mint(address[] calldata toList, uint256[] calldata tokenIdList) external {
        require(toList.length == tokenIdList.length, "input length must be same");

        for (uint256 i = 0; i < tokenIdList.length; i++) {
            mint(toList[i], tokenIdList[i]);
        }
    }

    function mintFor(address to, uint256 tokenId) external {
        mint(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override checkLock {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override checkLock {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override checkLock {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        emit Unlocked(tokenId);
    }

    function burn(uint256 tokenId) external checkLock {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function locked(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _isLocked;
    }

    function approve(address approved, uint256 tokenId) public override checkLock {
        super.approve(approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override checkLock {
        super.setApprovalForAll(operator, approved);
    }

    function _baseURI() internal view override returns (string memory) {
        if (bytes(baseURI).length > 0) {
            return baseURI;
        }
        return string(abi.encodePacked("https://example/metadata/", symbol(), "/"));
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 /* batchSize*/
    )
        internal
        override
    {
        if (_isLocked && !(from == address(0) || to == address(0))) {
            super._approve(owner(), firstTokenId);
        }
    }
}
