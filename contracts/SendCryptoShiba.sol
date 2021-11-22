// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoShibaNFT.sol";
import "./ManagerInterface.sol";

contract SendCryptoShiba is Ownable{
    using SafeMath for uint256;

    address public cryptoShibaNFT;
    ManagerInterface manager;

    constructor (){
        cryptoShibaNFT = address(0x643a211d36B745864D89EBc1913140CEDA7d1323);
    }

    function setCryptoShibaNFT(address _nftAddress) public onlyOwner{
        cryptoShibaNFT = _nftAddress;
    }

    function createShiba(address receiver) public onlyOwner{
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        manager = ManagerInterface(cryptoShiba.manager());
        require(cryptoShiba.totalSupply() <= manager.nftMaxSize(), "Sold Out");
        uint8 tribe = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, receiver, cryptoShiba.balanceOf(receiver)))) % 4);
        uint8[] memory tribes = new uint8[](1);
        tribes[0] = tribe;
        cryptoShiba.layShiba(receiver, tribes);
    }
}