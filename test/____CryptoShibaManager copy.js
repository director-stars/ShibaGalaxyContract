const { BN, ether, balance } = require('openzeppelin-test-helpers');

const CryptoShibaManager = artifacts.require('CryptoShibaManager')
const CryptoShibaController = artifacts.require('CryptoShibaController');
const CryptoShibaNFT = artifacts.require('CryptoShibaNFT')
const CreateCryptoShiba = artifacts.require('CreateCryptoShiba')
const MarketController = artifacts.require('MarketController')
const ForceSend = artifacts.require('ForceSend');
const shibaGalaxyABI = require('./abi/shibaGalaxy');

const shibaGalaxyAddress = '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56';
const shibaGalaxyContract = new web3.eth.Contract(shibaGalaxyABI, shibaGalaxyAddress);
const shibaGalaxyOwner = '0x8c7de13ecf6e92e249696defed7aa81e9c93931a';

contract('test CryptoShibaManager', async([alice, bob, admin, dev, minter]) => {

    before(async () => {
        this.cryptoShibaManager = await CryptoShibaManager.new(
            {
                from: alice
            });
            
        this.cryptoShibaNFT = await CryptoShibaNFT.new(
            'CryptoShibaNFT',
            'CryptoShibaNFT',
            this.cryptoShibaManager.address,
            shibaGalaxyAddress,
        {
            from: alice
        });

        this.cryptoShibaController = await CryptoShibaController.new({ from: alice });

        this.createCryptoShiba = await CreateCryptoShiba.new({ from: alice });
        
        this.marketController = await MarketController.new({ from: alice });
    });

    it('manager test', async() => {
        
        await this.cryptoShibaManager.addBattlefields(this.cryptoShibaController.address);
        await this.cryptoShibaManager.addMarkets(this.cryptoShibaNFT.address);
        await this.cryptoShibaManager.setFeeAddress(this.marketController.address);
        // await this.cryptoShibaManager.addEvolvers(this.cryptoShibaNFT.address);
        await this.cryptoShibaController.setCryptoShibaNFT(this.cryptoShibaNFT.address);

        await this.cryptoShibaManager.addEvolvers(this.createCryptoShiba.address);
        await this.createCryptoShiba.setCryptoShibaNFT(this.cryptoShibaNFT.address);
        // await this.createCryptoShiba.setManager(this.cryptoShibaManager.address);

        await this.marketController.setCryptoShibaNFT(this.cryptoShibaNFT.address);
        await this.marketController.setCreateCryptoShiba(this.createCryptoShiba.address);

        console.log(await this.createCryptoShiba.cryptoShibaNFT());

        const forceSend = await ForceSend.new();
        await forceSend.go(shibaGalaxyOwner, { value: ether('1') });

        console.log('balance of shibaGalaxyOwner: ', await shibaGalaxyContract.methods.balanceOf(shibaGalaxyOwner).call());
        
        await shibaGalaxyContract.methods.transfer(alice, '100000000000000000000').send({ from: shibaGalaxyOwner});
        await shibaGalaxyContract.methods.transfer(admin, '100000000000000000000').send({ from: shibaGalaxyOwner});

        await shibaGalaxyContract.methods.transfer(this.cryptoShibaController.address, '100000000000000000000').send({ from: shibaGalaxyOwner});
        
        console.log('test');
        let priceShiba = await this.cryptoShibaNFT.priceShiba();
        console.log('priceShiba', priceShiba);

        let tribe = Math.floor(Math.random() * 4);
        console.log('tribe', tribe);
        // console.log(this.cryptoShibaController.address)
        await shibaGalaxyContract.methods.approve(this.createCryptoShiba.address, priceShiba).send({ from : alice});
        let Shiba = await this.createCryptoShiba.buyShiba([tribe], bob, { from : alice });
        await shibaGalaxyContract.methods.approve(this.createCryptoShiba.address, priceShiba).send({ from : admin});
        await this.createCryptoShiba.buyShiba([tribe], bob, { from : admin });
        // console.log(Shiba.logs[0].args);
        let cryptoShibas = await this.cryptoShibaNFT.balanceOf(alice);
        let cryptoShibas_1 = await this.cryptoShibaNFT.balanceOf(admin);
        
        console.log('cryptoShibas', cryptoShibas.toString());
        let tokenId = await this.cryptoShibaNFT.tokenOfOwnerByIndex(alice, parseInt(cryptoShibas.toString())-1);
        let tokenId_1 = await this.cryptoShibaNFT.tokenOfOwnerByIndex(admin, parseInt(cryptoShibas_1.toString())-1);
        await this.createCryptoShiba.setDNA(tokenId, { from : alice });
        await this.createCryptoShiba.setDNA(tokenId_1, { from : admin });
        console.log(parseInt(tokenId.toString()));

        let balance_A = await shibaGalaxyContract.methods.balanceOf(alice).call();

        console.log('balance_A', await balance_A.toString());
        
        let result = await this.cryptoShibaController.fight(tokenId, alice, 0, false);
        // console.log(result);
        let claimTokenAmount = await this.cryptoShibaController.claimTokenAmount(alice);
        console.log('claimTokenAmount', claimTokenAmount.toString());

        await this.cryptoShibaController.claimToken({from: alice});

        balance_A = await shibaGalaxyContract.methods.balanceOf(alice).call();

        console.log('balance_B', balance_A.toString());

        // result = await this.cryptoShibaController.fight(tokenId, alice, 0, true);

        // console.log(result)

        // console.log('alice', alice)
        // console.log(await this.cryptoShibaNFT.ownerOf(tokenId));

        await this.cryptoShibaNFT.placeOrder(tokenId, 1000, {from: alice});
        await this.cryptoShibaNFT.placeOrder(tokenId_1, 1000, {from: admin});
        console.log('result-----------')
        result = await this.marketController.getShibaOfSaleByOwner({from: alice});
        console.log('result', result);
        result = await this.marketController.getShibaOfSale();
        console.log('result', result);
        result = await this.marketController.getShibaByOwner({from: alice});


        const referral_balance = await shibaGalaxyContract.methods.balanceOf(bob).call();
        console.log(referral_balance.toString());

        result = await this.cryptoShibaNFT.fillOrder(tokenId, bob, {from: admin});
        console.log('////////////////////////');
        // result = await this.cryptoShibaNFT.orders(alice);
        // result = await this.cryptoShibaNFT.tokenSaleOfOwnerByIndex(alice, 0);
        // result = await this.cryptoShibaNFT.balanceOf(alice);
        // result = await this.cryptoShibaNFT.balanceOf(alice);
        // console.log('result', result.toString());
        // result = await this.marketController.getShibasInfo([1]);
        // console.log(result);
        // result = await this.cryptoShibaNFT.balanceOf(admin);
        // console.log('result', result.toString());
    })
})