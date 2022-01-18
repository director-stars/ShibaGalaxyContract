// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoShibaNFT.sol";
import "./ManagerInterface.sol";
import "./IMagicStoneNFT.sol";

interface IUniswapV2Router02{
  function WETH() external pure returns (address);
}

interface IcryptoShibaController{
    function monsters(uint256 _index) external view returns(uint256 _hp, uint256 _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo);
    function maxFightNumber() external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
    function cooldownTime() external view returns(uint256);
    function priceCheck(address start, address end, uint256 _amount) external view returns (uint256);
}

contract MagicStoneController is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Monster{
        uint256 _hp;
        uint256 _successRate;
        uint256 _rewardTokenFrom;
        uint256 _rewardTokenTo;
        uint256 _rewardExpFrom;
        uint256 _rewardExpTo;
    }

    address public token;
    IUniswapV2Router02 public _uniswapV2Router;

    address public cryptoShibaNFT;
    address public cryptoShibaController;
    address public magicStoneNFT;
    address public feeAddress;
    ManagerInterface manager;

    uint256 internal fightRandNonce = 0;
    uint256 public nftMaxSize = 1000;

    mapping (uint256 => uint256) public battleTime;
    mapping (uint256 => uint256) public setStoneTime;
    mapping (uint256 => uint256) public shibaStoneInfo;
    mapping (uint256 => uint256) public stoneShibaInfo;
    mapping (uint256 => uint256) public autoFightMonsterInfo;
    event SetAutoFight(uint256 _tokenId, uint256 _monsterId);
    event Fight(uint256 _tokenId, uint256 _totalRewardAmount, uint256 _totalRewardExp, uint256 _winNumber, uint256 _fightNumber);

    constructor (){
        token = address(0x7420d2Bc1f8efB491D67Ee860DF1D35fe49ffb8C);
        _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancakeswap Router
        cryptoShibaNFT = address(0x5E33FB9f02E445533308aBE005B7e270FDd79CD8);
        magicStoneNFT = address(0xC6E6BE483bC1048c05DFE3d7Ed03455BF067b348);
        cryptoShibaController = address(0xa3F7CDEa4E7F8B0F97d33Be6d8Fc84842fc556ce);
        feeAddress = address(0xD8E92ef99da5874B7B30ba24722871CB799c045E);
    }

    receive() external payable {}

    function setCryptoShibaNFT(address _nftAddress) public onlyOwner{
        cryptoShibaNFT = _nftAddress;
    }

    function setMagicStoneNFT(address _magicStoneNFT) public onlyOwner{
        magicStoneNFT = _magicStoneNFT;
    }

    function setCryptoShibaController(address _cryptoShibaController) public onlyOwner{
        cryptoShibaController = _cryptoShibaController;
    }

    function setNftMaxSize(uint256 _nftMaxSize) public onlyOwner{
        nftMaxSize = _nftMaxSize;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner{
        feeAddress = _feeAddress;
    }

    function buyStone(bool isBnb) external payable{
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        IMagicStoneNFT magicStone = IMagicStoneNFT(magicStoneNFT);
        require(magicStone.totalSupply() <= nftMaxSize, "Sold Out");
        manager = ManagerInterface(cryptoShiba.manager());
        uint256 price = 0;
        price = magicStone.priceStone();
        require(msg.value >= price, "MAGICSTONENFT: confirmOffer: deposited BNB is less than NFT price." );
        (bool success,) = payable(feeAddress).call{value: price}("");
        require(success, "Failed to send BNB");
        
        magicStone.createStone(_msgSender());
    }
    function setAutoFight(uint256 _shibaId,uint256 _stoneId, uint256 _monsterId) public {
        ICryptoShibaNFT shibaNFT = ICryptoShibaNFT(cryptoShibaNFT);
        IMagicStoneNFT stoneNFT = IMagicStoneNFT(magicStoneNFT);
        require(shibaNFT.ownerOf(_shibaId) == _msgSender(), 'not owner of shiba');
        require(stoneNFT.ownerOf(_stoneId) == _msgSender(), 'not owner of stone');
        uint256 currentSetShibaId = stoneShibaInfo[_stoneId];
        stoneShibaInfo[_stoneId] = 0;
        shibaStoneInfo[currentSetShibaId] = 0;
        setStoneTime[_stoneId] = 0;

        shibaStoneInfo[_shibaId] = _stoneId;
        setStoneTime[_stoneId] = block.timestamp;
        autoFightMonsterInfo[_stoneId] = _monsterId;
        stoneShibaInfo[_stoneId] = _shibaId;
        emit SetAutoFight(_shibaId, _monsterId);
    }

    function unsetAutoFight(uint256 _shibaId) public {
        ICryptoShibaNFT shibaNFT = ICryptoShibaNFT(cryptoShibaNFT);
        require(shibaNFT.ownerOf(_shibaId) == _msgSender(), 'not owner of shiba');
        uint256 _stoneId = shibaStoneInfo[_shibaId];
        setStoneTime[_stoneId] = 0;
        stoneShibaInfo[_stoneId] = 0;
        shibaStoneInfo[_shibaId] = 0;
    }

    function getAutoFightResults(uint256 _shibaId) public {
        ICryptoShibaNFT shibaNFT = ICryptoShibaNFT(cryptoShibaNFT);
        IMagicStoneNFT stoneNFT = IMagicStoneNFT(magicStoneNFT);
        uint256 _stoneId = shibaStoneInfo[_shibaId];
        uint256 setTime = setStoneTime[_stoneId];
        require(shibaNFT.ownerOf(_shibaId) == _msgSender(), 'not owner of shiba');
        require(stoneNFT.ownerOf(_stoneId) == _msgSender(), 'not set autoFight');
        require(setTime != 0, 'not set autoFight');
    
        (uint256 fightNumber, uint256 winNumber, uint256 totalRewardAmount, uint256 totalRewardExp) = battleResult(_shibaId);
        shibaNFT.updateClaimTokenAmount(_msgSender(), shibaNFT.getClaimTokenAmount(_msgSender()) + (totalRewardAmount * 10 ** 9));
        shibaNFT.updateTotalClaimTokenAmount(_msgSender(), totalRewardAmount * 10 ** 9);
        if(totalRewardExp > 0)
            shibaNFT.exp(_shibaId, totalRewardExp);
        battleTime[_shibaId] = block.timestamp;
        emit Fight(_shibaId, totalRewardAmount, totalRewardExp, winNumber, fightNumber);

    }
    function battleResult(uint256 _shibaId) private returns(uint256 fightNumber, uint256 winNumber, uint256 totalRewardAmount, uint256 totalRewardExp){
        ICryptoShibaNFT shibaNFT = ICryptoShibaNFT(cryptoShibaNFT);
        IcryptoShibaController shibaController = IcryptoShibaController(cryptoShibaController);
        Monster memory monster;
        {
            uint256 monsterId = autoFightMonsterInfo[_shibaId];
            (uint256 _hp, uint256 _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) = shibaController.monsters(monsterId);

            monster = Monster({
                _hp: _hp, 
                _successRate: _successRate, 
                _rewardTokenFrom: _rewardTokenFrom, 
                _rewardTokenTo: _rewardTokenTo, 
                _rewardExpFrom: _rewardExpFrom, 
                _rewardExpTo: _rewardExpTo}
            );
        }
        uint256 setTime = setStoneTime[shibaStoneInfo[_shibaId]];
        if(shibaController.battleTime(_shibaId) > battleTime[_shibaId]){
            battleTime[_shibaId] = shibaController.battleTime(_shibaId);
        }
        
        uint256 lastBattleTime = battleTime[_shibaId];
        uint256 i = 0;
        uint256 level = shibaNFT.shibaLevel(_shibaId);
        uint256 rare = shibaNFT.getRare(_shibaId);
        uint256 fightRandResult = 0;
        if(block.timestamp - setTime < shibaController.cooldownTime()){
            if(lastBattleTime == 0)
                fightNumber = shibaController.maxFightNumber();
        }
        else{
            if(lastBattleTime == 0)
                lastBattleTime = setTime;
            uint256 turns = (block.timestamp - lastBattleTime).div(shibaController.cooldownTime());
            uint256 totalFightNumber = 0;
            for(; i < turns; i ++){
                totalFightNumber = totalFightNumber.add(shibaController.maxFightNumber());
            }
            fightNumber = totalFightNumber;
        }
        uint256 updatedAttackVictoryProbability = 0;
        for(i = 0 ; i < fightNumber; i ++){
            fightRandNonce ++;
            fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce)));
            updatedAttackVictoryProbability = monster._successRate + (100 - monster._successRate) * level * rare / 6 / 6 / 2;

            if(fightRandResult % 100 < updatedAttackVictoryProbability){
                totalRewardAmount += monster._rewardTokenFrom + (fightRandResult % (monster._rewardTokenTo - monster._rewardTokenFrom + 1));
                totalRewardExp += monster._rewardExpFrom + (fightRandResult % (monster._rewardExpTo - monster._rewardExpFrom + 1));
                winNumber ++;                
            }
        }
        return (fightNumber, winNumber, totalRewardAmount, totalRewardExp);
    }

    function getTokenAmountForStone() public view returns (uint256){
        IMagicStoneNFT magicStone = IMagicStoneNFT(magicStoneNFT);
        IcryptoShibaController shibaController = IcryptoShibaController(cryptoShibaController);
        uint256 priceStone = magicStone.priceStone();
        uint256 amount = shibaController.priceCheck(_uniswapV2Router.WETH(), token, priceStone);
        return amount;
    }
}