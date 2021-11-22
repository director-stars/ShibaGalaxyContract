// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoShibaNFT.sol";
import "./IMagicStoneNFT.sol";

interface ICryptoShibaController{
    function getClassInfo(uint256 _tokenId) external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
    function setStoneTime(uint256 _tokenId) external view returns(uint256);
    function cooldownTime() external view returns(uint256);
    function stoneInfo(uint256 _tokenId) external view returns(uint256);
}

interface IMagicStoneController{
    function stoneShibaInfo(uint256 _stoneId) external view returns(uint256);
    function shibaStoneInfo(uint256 _shibaId) external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
}
contract MarketController is Ownable{

    struct Shiba{
        uint256 _tokenId;
        uint256 _generation;
        uint256 _tribe;
        uint256 _exp;
        uint256 _dna;
        uint256 _farmTime;
        uint256 _bornTime;
        uint256 _rare;
        uint256 _level;
        bool _isEvolved;
        uint256 _salePrice;
        address _owner;
        uint256 _classInfo;
        uint256 _availableBattleTime;
        uint256 _stoneInfo;
    }

    struct Stone{
        uint256 _tokenId;
        uint256 _shibaId;
    }

    address public cryptoShibaNFT;
    address public cryptoShibaController;
    address public magicStoneNFT;
    address public magicStoneController;
    
    constructor (){
        cryptoShibaNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        cryptoShibaController = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneController = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
    }

    function setCryptoShibaNFT(address _nftAddress) public onlyOwner{
        cryptoShibaNFT = _nftAddress;
    }

    function setCryptoShibaController(address _address) public onlyOwner{
        cryptoShibaController = _address;
    }

    function setMagicStoneNFT(address _nftAddress) public onlyOwner{
        magicStoneNFT = _nftAddress;
    }

    function setMagicStoneController(address _address) public onlyOwner{
        magicStoneController = _address;
    }

    function getShibasInfo(uint256[] memory ids) public view returns(Shiba[] memory){
        uint256 totalShibas = ids.length;
        Shiba[] memory shibas= new Shiba[](totalShibas);
        for(uint256 i = 0; i < totalShibas; i ++){
            shibas[i]._tokenId = ids[i];
            (uint256 _generation, uint256 _tribe, uint256 _exp, uint256 _dna, uint256 _farmTime, uint256 _bornTime) = ICryptoShibaNFT(cryptoShibaNFT).getShiba(ids[i]);
            shibas[i]._generation = _generation;
            shibas[i]._tribe = _tribe;
            shibas[i]._exp = _exp;
            shibas[i]._dna = _dna;
            shibas[i]._farmTime = _farmTime;
            shibas[i]._bornTime = _bornTime;
            shibas[i]._rare = ICryptoShibaNFT(cryptoShibaNFT).getRare(ids[i]);
            shibas[i]._level = ICryptoShibaNFT(cryptoShibaNFT).shibaLevel(ids[i]);
            shibas[i]._isEvolved = ICryptoShibaNFT(cryptoShibaNFT).isEvolved(ids[i]);
            (, address owner, uint256 price) = ICryptoShibaNFT(cryptoShibaNFT).getSale(ids[i]);
            if(owner != address(0))
                shibas[i]._owner = owner;
            else
                shibas[i]._owner = ICryptoShibaNFT(cryptoShibaNFT).ownerOf(ids[i]);
            shibas[i]._salePrice = price;
            shibas[i]._classInfo = ICryptoShibaController(cryptoShibaController).getClassInfo(ids[i]);

            shibas[i]._stoneInfo = IMagicStoneController(magicStoneController).shibaStoneInfo(ids[i]);
            if(shibas[i]._stoneInfo == 0)
                shibas[i]._availableBattleTime = ICryptoShibaController(cryptoShibaController).battleTime(ids[i]) + ICryptoShibaController(cryptoShibaController).cooldownTime();
            else
                shibas[i]._availableBattleTime = IMagicStoneController(magicStoneController).battleTime(ids[i]) + ICryptoShibaController(cryptoShibaController).cooldownTime();
            
        }
        return shibas;
    }

    function getShibaOfSaleByOwner() public view returns(Shiba[] memory){
        uint256 totalShibas = ICryptoShibaNFT(cryptoShibaNFT).orders(msg.sender);
        uint256[] memory ids = new uint256[](totalShibas);
        uint256 i = 0;
        for(; i < totalShibas; i ++){
            ids[i] = ICryptoShibaNFT(cryptoShibaNFT).tokenSaleOfOwnerByIndex(msg.sender, i);
        }
        return getShibasInfo(ids);
    }

    function getShibaOfSale() public returns(Shiba[] memory){
        uint256 totalShibas = ICryptoShibaNFT(cryptoShibaNFT).marketsSize();
        uint256[] memory ids = new uint256[](totalShibas);
        uint256 i = 0;
        for(; i < totalShibas; i ++){
            ids[i] = ICryptoShibaNFT(cryptoShibaNFT).tokenSaleByIndex(i);
        }
        return getShibasInfo(ids);
    }
    
    function getShibaByOwner() public view returns(Shiba[] memory){
        uint256 totalShibas = ICryptoShibaNFT(cryptoShibaNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalShibas);
        uint256 i = 0;
        for(; i < totalShibas; i ++){
            ids[i] = ICryptoShibaNFT(cryptoShibaNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getShibasInfo(ids);
    }

    function getStonesInfo(uint256[] memory ids) public view returns(Stone[] memory){
        uint256 totalStones = ids.length;
        Stone[] memory stones= new Stone[](totalStones);
        for(uint256 i = 0; i < totalStones; i ++){
            stones[i]._tokenId = ids[i];
            stones[i]._shibaId = IMagicStoneController(magicStoneController).stoneShibaInfo(ids[i]);
        }
        return stones;
    }

    function getStoneByOwner() public view returns(Stone[] memory){
        uint256 totalStones = IMagicStoneNFT(magicStoneNFT).balanceOf(msg.sender);
        uint256[] memory ids = new uint256[](totalStones);
        uint256 i = 0;
        for(; i < totalStones; i ++){
            ids[i] = IMagicStoneNFT(magicStoneNFT).tokenOfOwnerByIndex(msg.sender, i);
        }
        return getStonesInfo(ids);
    }
}