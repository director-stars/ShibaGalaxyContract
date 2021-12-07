// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ERC721.sol";

contract CryptoShibaNFT is ERC721 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    enum Tribe {
        FIRE,
        ELECTRIC,
        SKY,
        GRASS
    }

    event LayShiba(uint256 indexed tokenId, address buyer);
    event Evolve(uint256 indexed tokenId, uint256 dna);
    event Buy(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );
    event UpdateTribe(uint256 indexed tokenId, Tribe tribe);
    event UpgradeGeneration(uint256 indexed tokenId, uint256 newGeneration);
    event Exp(uint256 indexed tokenId, uint256 exp);
    event Working(uint256 indexed tokenId, uint256 time);
    event PlaceOrder(uint256 indexed tokenId, address seller, uint256 price);
    event CancelOrder(uint256 indexed tokenId, address seller);
    event UpdatePrice(
        uint256 indexed tokenId,
        address seller,
        uint256 newPrice
    );
    event FillOrder(uint256 indexed tokenId, address seller);

    struct CryptoShiba {
        uint256 generation;
        Tribe tribe;
        uint256 exp;
        uint256 dna;
        uint256 classInfo;
        uint256 farmTime;
        uint256 bornTime;
    }

    struct ItemSale {
        uint256 tokenId;
        address owner;
        uint256 price;
    }

    uint256 public latestTokenId;
    mapping(uint256 => bool) public isEvolved;

    mapping(uint256 => CryptoShiba) internal shibas;
    mapping(uint256 => ItemSale) internal markets;

    EnumerableSet.UintSet private tokenSales;
    mapping(address => EnumerableSet.UintSet) private sellerTokens;
    mapping(address => uint256) public firstPurchaseTime;
    mapping (address => uint256) private claimTokenAmount;
    mapping (address => uint256) private totalClaimTokenAmount;

    IERC20 public shibaERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        address _manager,
        address _shibaERC20
    ) ERC721(_name, _symbol, _manager) {
        shibaERC20 = IERC20(_shibaERC20);
    }

    modifier onlyFarmer() {
        require(manager.farmOwners(msg.sender), "require Farmer.");
        _;
    }

    modifier onlySpawner() {
        require(manager.evolvers(msg.sender), "require Spawner.");
        _;
    }

    modifier onlyBattlefield() {
        require(manager.battlefields(msg.sender), "require Battlefield.");
        _;
    }

    function priceShiba() public view returns (uint256) {
        return manager.priceShiba();
    }

    function feeEvolve() public view returns (uint256) {
        return manager.feeEvolve();
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);

        _incrementTokenId();
    }

    function working(uint256 _tokenId, uint256 _time) public onlyFarmer {
        require(_time > 0, "no time");
        CryptoShiba storage shiba = shibas[_tokenId];
        shiba.farmTime = shiba.farmTime.add(_time);

        emit Working(_tokenId, _time);
    }

    function exp(uint256 _tokenId, uint256 _exp) public onlyBattlefield {
        require(_exp > 0, "no exp");
        CryptoShiba storage shiba = shibas[_tokenId];
        shiba.exp = shiba.exp.add(_exp);
        emit Exp(_tokenId, _exp);
    }

    function evolve(
        uint256 _tokenId,
        address _owner,
        uint256 _dna,
        uint256[6] memory _classes
    ) public onlySpawner {
        require(ownerOf(_tokenId) == _owner, "not own");
        CryptoShiba storage shiba = shibas[_tokenId];
        require(!isEvolved[_tokenId], "require: not evolved");

        shiba.bornTime = block.timestamp;
        shiba.dna = _dna;
        isEvolved[_tokenId] = true;
        uint256 rare = getRare(_tokenId);
        shiba.classInfo = _dna % _classes[rare.sub(1)];

        emit Evolve(_tokenId, _dna);
    }

    function changeTribe(
        uint256 _tokenId,
        address _owner,
        Tribe tribe
    ) external onlySpawner {
        require(ownerOf(_tokenId) == _owner, "not own");
        shibaERC20.transferFrom(
            _msgSender(),
            manager.feeAddress(),
            manager.feeChangeTribe()
        );

        CryptoShiba storage shiba = shibas[_tokenId];
        shiba.tribe = tribe;

        emit UpdateTribe(_tokenId, tribe);
    }

    function upgradeGeneration(
        uint256 _tokenId,
        address _owner,
        uint256 _generation
    ) external onlySpawner {
        require(ownerOf(_tokenId) == _owner, "not own");
        shibaERC20.transferFrom(
            _msgSender(),
            manager.feeAddress(),
            manager.feeUpgradeGeneration()
        );

        CryptoShiba storage shiba = shibas[_tokenId];
        shiba.generation = _generation;

        emit UpgradeGeneration(_tokenId, _generation);
    }

    function layShiba(address receiver, Tribe[] memory tribes)
        external
        onlySpawner
    {
        uint256 amount = tribes.length;
        require(amount > 0, "require: >0");
        if (amount == 1) _layShiba(receiver, tribes[0]);
        else
            for (uint256 index = 0; index < amount; index++) {
                _layShiba(receiver, tribes[index]);
            }
    }

    function _layShiba(address receiver, Tribe tribe) internal {
        uint256 nextTokenId = _getNextTokenId();
        _mint(receiver, nextTokenId);

        shibas[nextTokenId] = CryptoShiba({
            generation: manager.generation(),
            tribe: tribe,
            exp: 0,
            dna: 0,
            classInfo: 0,
            farmTime: 0,
            bornTime: block.timestamp
        });

        emit LayShiba(nextTokenId, receiver);
    }

    /**
     * @dev calculates the next token ID based on value of latestTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return latestTokenId.add(1);
    }

    /**
     * @dev increments the value of latestTokenId
     */
    function _incrementTokenId() private {
        latestTokenId++;
    }

    function getShiba(uint256 _tokenId)
        public
        view
        returns (CryptoShiba memory)
    {
        return shibas[_tokenId];
    }

    function shibaLevel(uint256 _tokenId) public view returns (uint256) {
        return getLevel(getShiba(_tokenId).exp);
    }

    function getRare(uint256 _tokenId) public view returns (uint256) {
        uint256 dna = getShiba(_tokenId).dna;
        if (dna == 0) return 0;
        uint256 rareParser = dna / 10**26;
        if (rareParser < 5225) {
            return 1;
        } else if (rareParser < 7837) {
            return 2;
        } else if (rareParser < 8707) {
            return 3;
        } else if (rareParser < 9360) {
            return 4;
        } else if (rareParser < 9708) {
            return 5;
        } else {
            return 6;
        }
    }

    function getLevel(uint256 _exp) internal pure returns (uint256) {
        if (_exp < 100) {
            return 1;
        } else if (_exp < 350) {
            return 2;
        } else if (_exp < 1000) {
            return 3;
        } else if (_exp < 2000) {
            return 4;
        } else if (_exp < 4000) {
            return 5;
        } else {
            return 6;
        }
    }

    function placeOrder(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == _msgSender(), "not own");
        require(_price > 0, "nothing is free");
        require(isEvolved[_tokenId], "require: evolved");

        tokenOrder(_tokenId, true, _price);

        emit PlaceOrder(_tokenId, _msgSender(), _price);
    }

    function cancelOrder(uint256 _tokenId) public {
        require(tokenSales.contains(_tokenId), "not sale");
        ItemSale storage itemSale = markets[_tokenId];
        require(itemSale.owner == _msgSender(), "not own");

        tokenOrder(_tokenId, false, 0);

        emit CancelOrder(_tokenId, _msgSender());
    }

    function updatePrice(uint256 _tokenId, uint256 _price) public {
        require(_price > 0, "nothing is free");
        require(tokenSales.contains(_tokenId), "not sale");
        ItemSale storage itemSale = markets[_tokenId];
        require(itemSale.owner == _msgSender(), "not own");

        itemSale.price = _price;

        emit UpdatePrice(_tokenId, _msgSender(), _price);
    }

    function fillOrder(uint256 _tokenId, address referral) public {
        require(tokenSales.contains(_tokenId), "not sale");
        require(balanceOf(_msgSender()).add(orders(_msgSender())) < manager.ownableMaxSize(), "already have enough");
        ItemSale storage itemSale = markets[_tokenId];
        uint256 feeMarket = itemSale.price.mul(manager.feeMarketRate()).div(
            manager.feeMarketRatePercent()
        );
        uint256 referralReward = 0;
        if(firstPurchaseTime[_msgSender()] == 0 && referral != address(0)) {
            firstPurchaseTime[_msgSender()] = block.timestamp;
            referralReward = itemSale.price.mul(manager.referralRate()).div(manager.referralRatePercent());
            shibaERC20.transferFrom(_msgSender(), referral, referralReward);
        }
        shibaERC20.transferFrom(_msgSender(), manager.feeAddress(), feeMarket);
        shibaERC20.transferFrom(
            _msgSender(),
            itemSale.owner,
            itemSale.price.sub(feeMarket).sub(referralReward)
        );

        tokenOrder(_tokenId, false, 0);
        emit FillOrder(_tokenId, _msgSender());
    }

    function tokenOrder(
        uint256 _tokenId,
        bool _sell,
        uint256 _price
    ) internal {
        ItemSale storage itemSale = markets[_tokenId];
        if (_sell) {
            transferFrom(_msgSender(), address(this), _tokenId);
            tokenSales.add(_tokenId);
            sellerTokens[_msgSender()].add(_tokenId);

            markets[_tokenId] = ItemSale({
                tokenId: _tokenId,
                price: _price,
                owner: _msgSender()
            });
        } else {
            transferFrom(address(this), _msgSender(), _tokenId);

            tokenSales.remove(_tokenId);
            sellerTokens[itemSale.owner].remove(_tokenId);
            markets[_tokenId] = ItemSale({
                tokenId: 0,
                price: 0,
                owner: address(0)
            });
        }
    }

    function marketsSize() public view returns (uint256) {
        return tokenSales.length();
    }

    function orders(address _seller) public view returns (uint256) {
        return sellerTokens[_seller].length();
    }

    function tokenSaleByIndex(uint256 index) public view returns (uint256) {
        return tokenSales.at(index);
    }

    function tokenSaleOfOwnerByIndex(address _seller, uint256 index)
        public
        view
        returns (uint256)
    {
        return sellerTokens[_seller].at(index);
    }

    function getSale(uint256 _tokenId) public view returns (ItemSale memory) {
        if (tokenSales.contains(_tokenId)) return markets[_tokenId];
        return ItemSale({tokenId: 0, owner: address(0), price: 0});
    }

    function setFirstPurchaseTime(address _address, uint256 _firstPurchaseTime) public onlySpawner{
        firstPurchaseTime[_address] = _firstPurchaseTime;
    }

    function getClaimTokenAmount(address _address) public view returns (uint256){
        return claimTokenAmount[_address];
    }

    function updateClaimTokenAmount(address _address, uint256 _amount) public onlySpawner{
        claimTokenAmount[_address] = _amount;
    }

    function getTotalClaimTokenAmount(address _address) public view returns (uint256){
        return totalClaimTokenAmount[_address];
    }

    function updateTotalClaimTokenAmount(address _address, uint256 _amount) public onlySpawner{
        totalClaimTokenAmount[_address] = totalClaimTokenAmount[_address].add(_amount);
    }
}