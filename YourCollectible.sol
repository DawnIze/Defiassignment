// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YourCollectible is ERC721, Ownable {
    constructor(address initialOwner)
        ERC721("DiamondToken", "DTK")
        Ownable(initialOwner)
    {}

    function Mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function ownerOf(uint256 tokenId) override public view returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function approve(address to, uint256 tokenId) public override virtual {
        _approve(to, tokenId, _msgSender());
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check for approval or ownership
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _isApprovedOrOwner(address _address, uint256 tokenId) public view returns (bool) {
        // require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return _address==owner || getApproved(tokenId) == _address;
    }

}