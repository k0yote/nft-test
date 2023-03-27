// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { IERC5192 } from "./interfaces/IERC5192.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {
    IERC721,
    IERC721Metadata,
    ERC721,
    ERC721URIStorage
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract ERC5192 is ERC721, ERC721URIStorage, Ownable {
    uint256 private _totalIssuedTokenAmount;
    uint256 private _totalBurntTokenAmount;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function mint(address _receiver, string calldata _tokenURI) external onlyOwner {
        _safeMint(_receiver, _totalIssuedTokenAmount);
        _setTokenURI(_totalIssuedTokenAmount, _tokenURI);

        _totalIssuedTokenAmount += 1;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
        _totalBurntTokenAmount += 1;
    }

    function locked(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "ERC5192: token does not exists");
        return true;
    }

    function totalIssuedTokens() public view returns (uint256) {
        return _totalIssuedTokenAmount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalIssuedTokenAmount + _totalBurntTokenAmount;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }

    function approve(address, uint256) public pure override {
        revert("Can not approve SBT");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("Can not approve SBT");
    }

    function _transfer(address, address, uint256) internal pure override {
        revert("Can not transfer SBT");
    }
}
