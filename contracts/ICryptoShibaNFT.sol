// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICryptoShibaNFT{
    function balanceOf(address owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function getShiba(uint256 _tokenId) external view returns(
        uint256 _generation,
        uint256 _tribe,
        uint256 _exp,
        uint256 _dna,
        uint256 _classInfo,
        uint256 _farmTime,
        uint256 _bornTime
    );
    function getSale(uint256 _tokenId) external view returns(
        uint256 tokenId,
        address owner,
        uint256 price
    );
    function isEvolved(uint256 _tokenId) external view returns(bool);
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function layShiba(address receiver, uint8[] memory tribe) external;
    function priceShiba() external view returns(uint256);
    function evolve(uint256 _tokenId, address _owner, uint256 _dna, uint256[6] memory classes) external;
    function getRare(uint256 _tokenId) external view returns(uint256);
    function exp(uint256 _tokenId, uint256 rewardExp) external;
    function shibaLevel(uint256 _tokenId) external view returns(uint256);
    function tokenByIndex(uint256 _tokenId) external view returns(uint256);
    function orders(address _owner) external view returns(uint256);
    function marketsSize() external view returns(uint256);
    function tokenSaleOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function tokenSaleByIndex(uint256 index) external view returns(uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function firstPurchaseTime(address _address) external view returns(uint256);
    function manager() external view returns(address);
    function setFirstPurchaseTime(address _address, uint256 _firstPurchaseTime) external;
    function totalSupply() external view returns(uint256);
    function getClaimTokenAmount(address _address) external view returns(uint256);
    function updateClaimTokenAmount(address _address, uint256 _newAmount) external;
    function updateTotalClaimTokenAmount(address _address, uint256 _amount) external;
}