// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoShibaNFT.sol";
import "./ManagerInterface.sol";

interface IUniswapV2Router02{
  function getAmountsOut(uint256 _amount, address[] calldata path) external view returns (uint256[] memory);
  function WETH() external pure returns (address);
}

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
    IUniswapV2Router02 public _uniswapV2Router;
    address public busdTokenAddress;

    uint256[6] public classes;
    ManagerInterface manager;
    event DNASet(uint256 _tokenId, uint256 _dna);

    uint256 public cooldownTime = 14400;
    uint256 internal fightRandNonce = 0;
    Monster[4] public monsters;

    mapping (uint256 => uint256) public battleTime;

    uint256 public claimPrice;
    uint256 public claimPriceDecimal = 2;
    uint256 public claimTimeCycle;
    mapping (address => uint256) public nextClaimTime;
    uint256 public maxFightNumber = 3;
    mapping (uint256 => uint256) public availableFightNumber;
    event Fight(uint256 _tokenId, uint256 _totalRewardAmount, uint256 _totalRewardExp, uint256 _winNumber, uint256 _fightNumber);

    constructor (){
        token = address(0x7420d2Bc1f8efB491D67Ee860DF1D35fe49ffb8C);
        busdTokenAddress = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancakeswap Router
        // token = address(0x4E01A14cfA1ae3C5e0507e126d9057E6f7979CaF);
        // cryptoShibaNFT = address(0xcF9ec47ED36CBB83eD2eBf632b9aA5b68efa054c);
        // busdTokenAddress = address(0xD1caDD2c2909351f37c8E75d66cC07deb3021601);
        // _uniswapV2Router = IUniswapV2Router02(0xf946634f04aa0eD1b935C8B876a0FD535F993D43); // Pancakeswap Router

        claimTimeCycle = 86400;
        claimPrice = 1000;
        classes[0] = 17;
        classes[1] = 10;
        classes[2] = 7;
        classes[3] = 7;
        classes[4] = 5;
        classes[5] = 5;

        monsters[0] = Monster({
            _hp: 200, 
            _successRate: 80, 
            _rewardTokenFrom: 60000, 
            _rewardTokenTo: 70000,
            _rewardExpFrom: 2, 
            _rewardExpTo: 2});
        monsters[1] = Monster({
            _hp: 250, 
            _successRate: 70, 
            _rewardTokenFrom: 70000, 
            _rewardTokenTo: 80000, 
            _rewardExpFrom: 6, 
            _rewardExpTo: 6});
        monsters[2] = Monster({
            _hp: 400, 
            _successRate: 50, 
            _rewardTokenFrom: 80000, 
            _rewardTokenTo: 90000, 
            _rewardExpFrom: 8, 
            _rewardExpTo: 8});
        monsters[3] = Monster({
            _hp: 600, 
            _successRate: 30, 
            _rewardTokenFrom: 90000, 
            _rewardTokenTo: 100000, 
            _rewardExpFrom: 12, 
            _rewardExpTo: 12});  
    }

    receive() external payable {}

    function setCryptoShibaNFT(address _nftAddress) public onlyOwner{
        cryptoShibaNFT = _nftAddress;
    }

    function buyShiba(uint8[] memory tribe, address referral, bool isBnb) external payable {
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        manager = ManagerInterface(cryptoShiba.manager());
        require(cryptoShiba.totalSupply() <= manager.nftMaxSize(), "Sold Out");
        require(cryptoShiba.balanceOf(_msgSender()).add(cryptoShiba.orders(_msgSender())).add(tribe.length) <= manager.ownableMaxSize(), "already have enough");
        uint256 totalPriceShiba = 0;
        if(isBnb)
            totalPriceShiba = cryptoShiba.priceShiba().mul(tribe.length);
        else
            totalPriceShiba = getTokenAmountForShiba().mul(tribe.length);
        uint256 firstPurchaseTime = cryptoShiba.firstPurchaseTime(_msgSender());
        uint256 referralRate = manager.referralRate();
        uint256 referralRatePercent = manager.referralRatePercent();
        uint256 referralReward = 0;

        if(isBnb)
            require(msg.value >= totalPriceShiba, "CryptoShibaNFT: confirmOffer: deposited BNB is less than NFT price." );
        else
            require(IERC20(token).balanceOf(_msgSender()) >= totalPriceShiba, "CryptoShibaNFT: confirmOffer: owner doesn't have enough token for NFT" );

        if(firstPurchaseTime == 0 && referral != address(0)){
            cryptoShiba.setFirstPurchaseTime(_msgSender(), block.timestamp);
            referralReward = totalPriceShiba.mul(referralRate).div(referralRatePercent);
            if(isBnb){
                (bool success,) = payable(referral).call{value: referralReward}("");
                require(success, "Failed to send BNB");
            }
            else{
                IERC20(token).safeTransferFrom(_msgSender(), referral, referralReward);
            }
        }
        if(isBnb){
            (bool success,) = payable(manager.feeAddress()).call{value: totalPriceShiba.sub(referralReward)}("");
            require(success, "Failed to send BNB");
        }
        else{
            IERC20(token).safeTransferFrom(_msgSender(), manager.feeAddress(), totalPriceShiba.sub(referralReward));
        }
        
        cryptoShiba.layShiba(_msgSender(), tribe);
        uint256 lastTokenId = cryptoShiba.tokenOfOwnerByIndex(_msgSender(), cryptoShiba.balanceOf(_msgSender()).sub(1));
        availableFightNumber[lastTokenId] = maxFightNumber;
    }

    function setDNA(uint256 tokenId) public {
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        require(cryptoShiba.ownerOf(tokenId) == _msgSender(), "not own");

        uint256 randNonce = cryptoShiba.balanceOf(_msgSender());
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % 10**30;
        cryptoShiba.evolve(tokenId, _msgSender(), dna, classes);

        // uint256 shibaRare = cryptoShiba.getRare(tokenId);
        // uint256 classInfo = dna % classes[shibaRare.sub(1)];

        emit DNASet(tokenId, dna);
    }

    function setClasses(uint256 rare, uint256 classNumber) public {
        classes[rare.sub(1)] = classNumber;
    }

    // function getClassInfo(uint256 tokenId) public view returns(uint256){
    //     return classInfo[tokenId];
    // }

    function fight(uint256 _tokenId, address _owner, uint256 monsterId) public{
        ICryptoShibaNFT myshiba = ICryptoShibaNFT(cryptoShibaNFT);
        require(myshiba.ownerOf(_tokenId) == _msgSender(), "not own");
        if(block.timestamp.div(cooldownTime) == battleTime[_tokenId].div(cooldownTime)){
            require(availableFightNumber[_tokenId] > 0, 'not available for fighting');
            availableFightNumber[_tokenId] = availableFightNumber[_tokenId] - 1;
        }
        else{
            availableFightNumber[_tokenId] = maxFightNumber - 1;
        }
        uint256 level = myshiba.shibaLevel(_tokenId);
        uint256 rare = myshiba.getRare(_tokenId);
        
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce)));
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (100 - monsters[monsterId]._successRate) * level * rare / 6 / 6 / 2;
        uint256 newAmount = 0;
        if(fightRandResult % 100 < updatedAttackVictoryProbability){
            _rewardTokenAmount = monsters[monsterId]._rewardTokenFrom + (fightRandResult % (monsters[monsterId]._rewardTokenTo - monsters[monsterId]._rewardTokenFrom + 1));
            _rewardExp = monsters[monsterId]._rewardExpFrom + (fightRandResult % (monsters[monsterId]._rewardExpTo - monsters[monsterId]._rewardExpFrom + 1));
            newAmount = myshiba.getClaimTokenAmount(_owner) + (_rewardTokenAmount * 10 ** 9);
            myshiba.updateClaimTokenAmount(_owner, newAmount);
            myshiba.updateTotalClaimTokenAmount(_owner, _rewardTokenAmount * 10 ** 9);
            myshiba.exp(_tokenId, _rewardExp);
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 1, 1);
        }
        else{
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 0, 1);
        }
        battleTime[_tokenId] = block.timestamp;
    }

    function claimToken() public{
        require(nextClaimTime[_msgSender()] < block.timestamp, "not claim now");
        ICryptoShibaNFT myshiba = ICryptoShibaNFT(cryptoShibaNFT);  
        uint256 nftBalance = myshiba.balanceOf(_msgSender());
        uint256 maxClaimAmount = priceCheck(busdTokenAddress, token, 1e18 * claimPrice / (10**claimPriceDecimal)).mul(nftBalance);
        uint256 amount = (myshiba.getClaimTokenAmount(_msgSender()) > maxClaimAmount)? maxClaimAmount : myshiba.getClaimTokenAmount(_msgSender());
        require(IERC20(token).balanceOf(address(this)) > amount, "ended claim token");
        IERC20(token).safeTransfer(_msgSender(), amount);
        nextClaimTime[_msgSender()] = block.timestamp.add(claimTimeCycle);
        myshiba.updateClaimTokenAmount(_msgSender(), myshiba.getClaimTokenAmount(_msgSender()).sub(amount));
    }

    function priceCheck(address start, address end, uint256 _amount) public view returns (uint256) {
        address wbnb = _uniswapV2Router.WETH();
        if (_amount == 0) {
        return 0;
        }

        address[] memory path;
        if (start == wbnb) {
        path = new address[](2);
        path[0] = wbnb;
        path[1] = end;
        } else {
        path = new address[](3);
        path[0] = start;
        path[1] = wbnb;
        path[2] = end;
        }

        uint256[] memory amounts = _uniswapV2Router.getAmountsOut(_amount, path);
        // [0x8f0528ce5ef7b51152a59745befdd91d97091d2f, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, 0x55d398326f99059fF775485246999027B3197955]
        return amounts[amounts.length - 1];
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

    // function setRandFightNumber(uint256 _randFightNumberFrom, uint256 _randFightNumberTo) public{
    //     assert(_randFightNumberTo >= randFightNumberFrom);
    //     randFightNumberFrom = _randFightNumberFrom;
    //     randFightNumberTo = _randFightNumberTo;
    // }

    function withdraw(address _address, uint256 amount) public onlyOwner{
        IERC20(token).safeTransfer(_address, amount);
    }
    function setCooldownTime(uint256 _seconds) public onlyOwner{
        cooldownTime = _seconds;
    }

    function setClaimPrice(uint256 _price) public onlyOwner {
        claimPrice = _price;    
    }

    function setClaimTimeCycle(uint256 _newCycle) public onlyOwner {
        claimTimeCycle = _newCycle;
    }

    function setMaxFightNumber(uint256 _maxFightNumber) public onlyOwner {
        maxFightNumber = _maxFightNumber;
    }

    function getTokenAmountForShiba() public view returns (uint256){
        ICryptoShibaNFT cryptoShiba = ICryptoShibaNFT(cryptoShibaNFT);
        uint256 priceShiba = cryptoShiba.priceShiba();
        uint256 amount = priceCheck(_uniswapV2Router.WETH(), token, priceShiba);
        return amount;
    }
}