// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721URIStorage, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { IERC6147 } from "./interfaces/IERC6147.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC6147 is ERC721, ERC721URIStorage, IERC6147, Ownable {
    using Strings for uint256;

    /// @dev A structure representing a token of guard address and expires
    /// @param guard address of guard role
    /// @param expirs UNIX timestamp, the guard could manage the token before expires
    struct GuardInfo {
        address guard;
        uint64 expires;
    }

    string private baseURI;
    bool private expireSwitch;

    mapping(uint256 => GuardInfo) internal _guardInfo;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) { }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
        changeGuard(tokenId, _msgSender(), 0);
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

    /// @notice Owner, authorised operators and approved address of the NFT can set guard and expires of the NFT and
    ///         valid guard can modifiy guard and expires of the NFT
    ///         If the NFT has a valid guard role, the owner, authorised operators and approved address of the NFT
    ///         cannot modify guard and expires
    /// @dev The `newGuard` can not be zero address
    ///      The `expires` need to be valid
    ///      Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to get the guard address for
    /// @param newGuard The new guard address of the NFT
    /// @param expires UNIX timestamp, the guard could manage the token before expires
    function changeGuard(uint256 tokenId, address newGuard, uint64 expires) public virtual {
        require(!expireSwitch || expires > block.timestamp, "ERC6147: invalid expires");
        _updateGuard(tokenId, newGuard, expires, false);
    }

    /// @notice Remove the guard and expires of the NFT
    ///         Only guard can remove its own guard role and expires
    /// @dev The guard address is set to 0 address
    ///      The expires is set to 0
    ///      Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to remove the guard and expires for
    function removeGuard(uint256 tokenId) public virtual {
        _updateGuard(tokenId, address(0), 0, true);
    }

    /// @notice Transfer the NFT and remove its guard and expires
    /// @dev The NFT is transferred to `to` and the guard address is set to 0 address
    ///      Throws if `tokenId` is not valid NFT
    /// @param from The address of the previous owner of the NFT
    /// @param to The address of NFT recipient
    /// @param tokenId The NFT to get transferred for
    function transferAndRemove(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId);
        removeGuard(tokenId);
    }

    /// @notice Get the guard address and expires of the NFT
    /// @dev The zero address indicates that there is no guard
    /// @param tokenId The NFT to get the guard address and expires for
    /// @return The guard address and expires for the NFT
    function guardInfo(uint256 tokenId) public view virtual returns (address, uint64) {
        if (!expireSwitch || _guardInfo[tokenId].expires >= block.timestamp) {
            return (_guardInfo[tokenId].guard, _guardInfo[tokenId].expires);
        } else {
            return (address(0), 0);
        }
    }

    /// @notice Update the guard of the NFT
    /// @dev Delete function: set guard to 0 address and set expires to 0;
    ///      and update function: set guard to new address and set expires
    ///      Throws if `tokenId` is not valid NFT
    /// @param tokenId The NFT to update the guard address for
    /// @param newGuard The newGuard address
    /// @param expires UNIX timestamp, the guard could manage the token before expires
    /// @param allowNull Allow 0 address
    function _updateGuard(uint256 tokenId, address newGuard, uint64 expires, bool allowNull) internal {
        (address guard,) = guardInfo(tokenId);
        if (!allowNull) {
            require(newGuard != address(0), "ERC6147: new guard can not be null");
        }
        if (guard != address(0)) {
            require(guard == _msgSender(), "ERC6147: only guard can change it self");
        } else {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC6147: caller is not owner nor approved");
        }

        if (guard != address(0) || newGuard != address(0)) {
            _guardInfo[tokenId] = GuardInfo(newGuard, expires);
            emit UpdateGuardLog(tokenId, newGuard, guard, expires);
        }
    }

    /// @notice Check the guard address
    /// @dev The zero address indicates there is no guard
    /// @param tokenId The NFT to check the guard address for
    /// @return The guard address
    function _checkGuard(uint256 tokenId) internal view returns (address) {
        (address guard,) = guardInfo(tokenId);
        address sender = _msgSender();
        if (guard != address(0)) {
            require(guard == sender, "ERC6147: sender is not guard of the token");
            return guard;
        } else {
            return address(0);
        }
    }

    /// @dev Before transferring the NFT, need to check the gurard address
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address guard;
        address new_from = from;
        if (from != address(0)) {
            guard = _checkGuard(tokenId);
            new_from = ownerOf(tokenId);
        }
        if (guard == address(0)) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(new_from, to, tokenId);
    }

    /// @dev Before safe transferring the NFT, need to check the gurard address
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address guard;
        address new_from = from;
        if (from != address(0)) {
            guard = _checkGuard(tokenId);
            new_from = ownerOf(tokenId);
        }
        if (guard == address(0)) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /// @dev When burning, delete `token_guard_map[tokenId]`
    /// This is an internal function that does not check if the sender is authorized to operate on the token.
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        (address guard,) = guardInfo(tokenId);
        super._burn(tokenId);
        delete _guardInfo[tokenId];
        emit UpdateGuardLog(tokenId, address(0), guard, 0);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC6147).interfaceId || super.supportsInterface(interfaceId);
    }

    function setExpireSwitchOn() public onlyOwner {
        expireSwitch = true;
    }

    function _baseURI() internal view override returns (string memory) {
        if (bytes(baseURI).length > 0) {
            return baseURI;
        }
        return string(abi.encodePacked("https://example/metadata/", symbol(), "/"));
    }
}
