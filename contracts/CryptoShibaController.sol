// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoShibaNFT.sol";
import "./ManagerInterface.sol";

contract CryptoShibaController is Ownable{
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

    address public cryptoShibaNFT;
    address public token;

    mapping (uint256 => uint256) private classInfo;
    uint256[6] public classes;
    uint256 public uncommonEstate;
    uint256 public rareEstate;
    uint256 public superRareEstate;
    uint256 public epicEstate;
    uint256 public legendaryEstate;
    ManagerInterface manager;
    event DNASet(uint256 _tokenId, uint256 _dna, uint256 _rare, uint256 _classInfo);

    uint256 public cooldownTime = 14400;
    uint256 internal fightRandNonce = 0;
    Monster[4] public monsters;

    mapping (uint256 => uint256) public battleTime;

    uint256 public randFightNumberFrom = 5;
    uint256 public randFightNumberTo = 10;
    uint256 public claimAmount;
    uint256 public claimTimeCycle;
    mapping (uint256 => uint256) public setStoneTime;
    mapping (uint256 => uint256) public stoneInfo;
    mapping (uint256 => uint256) public autoFightMonsterInfo;
    mapping (address => uint256) public nextClaimTime;
    event SetAutoFight(uint256 _tokenId, uint256 _monsterId);
    event Fight(uint256 _tokenId, uint256 _totalRewardAmount, uint256 _totalRewardExp, uint256 _winNumber, uint256 _fightNumber);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoShibaNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        claimTimeCycle = 85400;
        claimAmount = 1500;
        classes[0] = 16;
        classes[1] = 7;
        classes[2] = 3;
        classes[3] = 3;
        classes[4] = 2;
        classes[5] = 2;  

        monsters[0] = Monster({
            _hp: 200, 
            _successRate: 80, 
            _rewardTokenFrom: 15, 
            _rewardTokenTo: 20, 
            _rewardExpFrom: 2, 
            _rewardExpTo: 2});
        monsters[1] = Monster({
            _hp: 250, 
            _successRate: 70, 
            _rewardTokenFrom: 27, 
            _rewardTokenTo: 36, 
            _rewardExpFrom: 6, 
            _rewardExpTo: 6});
        monsters[2] = Monster({
            _hp: 400, 
            _successRate: 50, 
            _rewardTokenFrom: 33, 
            _rewardTokenTo: 44, 
            _rewardExpFrom: 8, 
            _rewardExpTo: 8});
        monsters[3] = Monster({
            _hp: 600, 
            _successRate: 30, 
            _rewardTokenFrom: 39, 
            _rewardTokenTo: 52, 
            _rewardExpFrom: 12, 
            _rewardExpTo: 12});  
    }

    receive() external payable {}

    function setCryptoShibaNFT(address _nftAddress) public onlyOwner{
        cryptoShibaNFT = _nftAddress;
    }

    function buyShiba(uint8[] memory tribe, address referral) public {
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        manager = ManagerInterface(cryptoShiba.manager());
        require(cryptoShiba.totalSupply() <= manager.nftMaxSize(), "Sold Out");
        require(cryptoShiba.balanceOf(_msgSender()).add(cryptoShiba.orders(_msgSender())).add(tribe.length) <= manager.ownableMaxSize(), "already have enough");
        uint256 totalPriceShiba = cryptoShiba.priceShiba().mul(tribe.length);
        uint256 firstPurchaseTime = cryptoShiba.firstPurchaseTime(_msgSender());
        uint256 referralRate = manager.referralRate();
        uint256 referralRatePercent = manager.referralRatePercent();
        uint256 referralReward = 0;

        if(firstPurchaseTime == 0 && referral != address(0)){
            cryptoShiba.setFirstPurchaseTime(_msgSender(), block.timestamp);
            referralReward = totalPriceShiba.mul(referralRate).div(referralRatePercent);
            IERC20(token).safeTransferFrom(_msgSender(), referral, referralReward);
        }
        IERC20(token).safeTransferFrom(_msgSender(), manager.feeAddress(), totalPriceShiba.sub(referralReward));
        
        cryptoShiba.layShiba(_msgSender(), tribe);
    }

    function setDNA(uint256 tokenId) public {
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        require(cryptoShiba.ownerOf(tokenId) == _msgSender(), "not own");

        uint256 randNonce = cryptoShiba.balanceOf(_msgSender());
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % 10**30;
        cryptoShiba.evolve(tokenId, _msgSender(), dna);

        uint256 shibaRare = cryptoShiba.getRare(tokenId);
        classInfo[tokenId] = dna % classes[shibaRare.sub(1)];
        emit DNASet(tokenId, dna, shibaRare, classInfo[tokenId]);
    }

    function setClasses(uint256 rare, uint256 classNumber) public {
        classes[rare.sub(1)] = classNumber;
    }

    function getClassInfo(uint256 tokenId) public view returns(uint256){
        return classInfo[tokenId];
    }

    function fight(uint256 _tokenId, address _owner, uint256 monsterId, bool _final) public{
        ICryptoShibaNFT myshiba = ICryptoShibaNFT(cryptoShibaNFT);
        require(myshiba.ownerOf(_tokenId) == _msgSender(), "not own");
        require(battleTime[_tokenId] + cooldownTime < block.timestamp, 'not available for fighting');
        uint256 level = myshiba.shibaLevel(_tokenId);
        uint256 rare = myshiba.getRare(_tokenId);
        
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce))) % 100;
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (100 - monsters[monsterId]._successRate) * level * rare / 6 / 6 / 2;
        uint256 newAmount = 0;
        if(fightRandResult < updatedAttackVictoryProbability){
            _rewardTokenAmount = monsters[monsterId]._rewardTokenFrom + (fightRandResult % (monsters[monsterId]._rewardTokenTo - monsters[monsterId]._rewardTokenFrom + 1));
            _rewardExp = monsters[monsterId]._rewardExpFrom + (fightRandResult % (monsters[monsterId]._rewardExpTo - monsters[monsterId]._rewardExpFrom + 1));
            newAmount = myshiba.getClaimTokenAmount(_owner) + (_rewardTokenAmount * 10**18);
            myshiba.updateClaimTokenAmount(_owner, newAmount);
            myshiba.exp(_tokenId, _rewardExp);
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 1, 1);
        }
        else{
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 0, 1);
        }
        if(_final){
            battleTime[_tokenId] = block.timestamp;
        }
    }

    function claimToken() public{
        require(nextClaimTime[_msgSender()] < block.timestamp, "not claim now");
        ICryptoShibaNFT myshiba = ICryptoShibaNFT(cryptoShibaNFT);
        uint256 amount = (myshiba.getClaimTokenAmount(_msgSender()) > (claimAmount * 10**18))? (claimAmount * 10**18) : myshiba.getClaimTokenAmount(_msgSender());
        require(IERC20(token).balanceOf(address(this)) > amount, "ended claim token");
        IERC20(token).safeTransfer(_msgSender(), amount);
        nextClaimTime[_msgSender()] = block.timestamp.add(claimTimeCycle);
        myshiba.updateClaimTokenAmount(_msgSender(), myshiba.getClaimTokenAmount(_msgSender()).sub(amount));
    }

    function setMonster(uint32 _index, uint256 _hp, uint _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) public onlyOwner{
        assert(_rewardTokenTo >=_rewardTokenFrom);
        assert(_rewardExpTo >=_rewardExpFrom);
        monsters[_index]._hp = _hp;
        monsters[_index]._successRate = _successRate;
        monsters[_index]._rewardTokenFrom = _rewardTokenFrom;
        monsters[_index]._rewardTokenTo = _rewardTokenTo;
        monsters[_index]._rewardExpFrom = _rewardExpFrom;
        monsters[_index]._rewardExpTo = _rewardExpTo;
    }

    function setRandFightNumber(uint256 _randFightNumberFrom, uint256 _randFightNumberTo) public{
        assert(_randFightNumberTo >= randFightNumberFrom);
        randFightNumberFrom = _randFightNumberFrom;
        randFightNumberTo = _randFightNumberTo;
    }

    function withdraw(address _address, uint256 amount) public onlyOwner{
        IERC20(token).safeTransfer(_address, amount);
    }
    function setCooldownTime(uint256 _seconds) public onlyOwner{
        cooldownTime = _seconds;
    }

    function setClaimAmount(uint256 _amount) public onlyOwner {
        claimAmount = _amount;    
    }

    function setClaimTimeCycle(uint256 _newCycle) public onlyOwner {
        claimTimeCycle = _newCycle;
    }
}