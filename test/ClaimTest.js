// const { BN, ether, balance } = require('openzeppelin-test-helpers');

// const CryptoShibaManager = artifacts.require('CryptoShibaManager')
// const CryptoShibaController = artifacts.require('CryptoShibaController');
// const CryptoShibaNFT = artifacts.require('CryptoShibaNFT')
// const MagicStoneNFT = artifacts.require('MagicStoneNFT')
// const MarketController = artifacts.require('MarketController')
// const ForceSend = artifacts.require('ForceSend');
const mkatABI = require('./abi/mkat');
const claimABI = require('./abi/claim');

const mkatAddress = '0x38Bd8CD90374DBc903AeD9d2eE28f5Ab856342Ce';
const claimAddress = '0xc990ff5175bde3c12b160787ac8a6570ba144b85';
const mkatContract = new web3.eth.Contract(mkatABI, mkatAddress);
const claimContract = new web3.eth.Contract(claimABI, claimAddress);

contract('test CryptoShibaManager', async([alice, bob, admin, dev, minter]) => {

    before(async () => {
    });

    it('manager test', async() => {
        await mkatContract.methods.approve(claimAddress, '10000000000000000000000000').send({ from : alice});
        await claimContract.methods.claimTokens().send({from: alice});
        let balance = await  mkatContract.methods.balanceOf(alice).call();
        console.log(balance.toString());
        
        // await this.cryptoShibaManager.addBattlefields(this.cryptoShibaController.address);
        // await this.cryptoShibaManager.addMarkets(this.cryptoShibaNFT.address);
        // await this.cryptoShibaManager.setFeeAddress(this.cryptoShibaController.address);
        // // await this.cryptoShibaManager.addEvolvers(this.cryptoShibaNFT.address);
        // await this.cryptoShibaController.setCryptoShibaNFT(this.cryptoShibaNFT.address);
        // await this.cryptoShibaController.setMagicStoneNFT(this.magicStoneNFT.address);

        // await this.cryptoShibaManager.addEvolvers(this.cryptoShibaController.address);
        // // await this.createCryptoShiba.setCryptoShibaNFT(this.cryptoShibaNFT.address);
        // // await this.createCryptoShiba.setManager(this.cryptoShibaManager.address);

        // await this.marketController.setCryptoShibaNFT(this.cryptoShibaNFT.address);
        // await this.marketController.setCryptoShibaController(this.cryptoShibaController.address);

        // console.log(await this.cryptoShibaController.cryptoShibaNFT());

        // const forceSend = await ForceSend.new();
        // await forceSend.go(shibaGalaxyOwner, { value: ether('1') });

        // console.log('balance of shibaGalaxyOwner: ', await shibaGalaxyContract.methods.balanceOf(shibaGalaxyOwner).call());
        
        // await shibaGalaxyContract.methods.transfer(alice, '100000000000000000000').send({ from: shibaGalaxyOwner});
        // await shibaGalaxyContract.methods.transfer(admin, '100000000000000000000').send({ from: shibaGalaxyOwner});

        // await shibaGalaxyContract.methods.transfer(this.cryptoShibaController.address, '100000000000000000000').send({ from: shibaGalaxyOwner});
        
        // console.log('test');
        // let priceShiba = await this.cryptoShibaNFT.priceShiba();
        // console.log('priceShiba', priceShiba);

        // let tribe = Math.floor(Math.random() * 4);
        // console.log('tribe', tribe);
        // // console.log(this.cryptoShibaController.address)
        // await shibaGalaxyContract.methods.approve(this.cryptoShibaController.address, priceShiba).send({ from : alice});
        // let Shiba = await this.cryptoShibaController.buyShiba([tribe], bob, { from : alice });
        // await shibaGalaxyContract.methods.approve(this.cryptoShibaController.address, priceShiba).send({ from : admin});
        // await this.cryptoShibaController.buyShiba([tribe], bob, { from : admin });
        // // console.log(Shiba.logs[0].args);
        // let cryptoShibas = await this.cryptoShibaNFT.balanceOf(alice);
        // let cryptoShibas_1 = await this.cryptoShibaNFT.balanceOf(admin);
        
        // console.log('cryptoShibas', cryptoShibas.toString());
        // let tokenId = await this.cryptoShibaNFT.tokenOfOwnerByIndex(alice, parseInt(cryptoShibas.toString())-1);
        // let tokenId_1 = await this.cryptoShibaNFT.tokenOfOwnerByIndex(admin, parseInt(cryptoShibas_1.toString())-1);
        // await this.cryptoShibaController.setDNA(tokenId, { from : alice });
        // await this.cryptoShibaController.setDNA(tokenId_1, { from : admin });
        // console.log(parseInt(tokenId.toString()));

        // let balance_A = await shibaGalaxyContract.methods.balanceOf(alice).call();

        // console.log('balance_A', await balance_A.toString());
        
        // let result = await this.cryptoShibaController.fight(tokenId, alice, 0, false);
        // // console.log(result);
        // let claimTokenAmount = await this.cryptoShibaNFT.getClaimTokenAmount(alice);
        // console.log('claimTokenAmount', claimTokenAmount.toString());

        // await this.cryptoShibaController.claimToken({from: alice});

        // balance_A = await shibaGalaxyContract.methods.balanceOf(alice).call();

        // console.log('balance_B', balance_A.toString());

        // // result = await this.cryptoShibaController.fight(tokenId, alice, 0, true);

        // // console.log(result)

        // // console.log('alice', alice)
        // // console.log(await this.cryptoShibaNFT.ownerOf(tokenId));

        // // await this.cryptoShibaNFT.placeOrder(tokenId, 1000, {from: alice});
        // await this.cryptoShibaNFT.placeOrder(tokenId_1, 1000, {from: admin});
        // console.log('result-----------')
        // result = await this.marketController.getShibaOfSaleByOwner({from: alice});
        // console.log('result', result);
        // result = await this.marketController.getShibaOfSale();
        // console.log('result', result);
        // result = await this.marketController.getShibaByOwner({from: alice});


        // const referral_balance = await shibaGalaxyContract.methods.balanceOf(bob).call();
        // console.log(referral_balance.toString());

        // let priceStone = await this.magicStoneNFT.priceStone();
        // console.log('priceStone', priceStone);
        // await shibaGalaxyContract.methods.approve(this.cryptoShibaController.address, priceStone).send({ from : alice});
        // // let owner = await this.cryptoShibaNFT.ownerOf(tokenId);
        // // console.log(owner);
        // // console.log(alice);
        // await this.cryptoShibaController.buyStone({from: alice, value: priceStone});
        // // let magicStones = await this.magicStoneNFT.balanceOf(alice);
        // // let stoneTokenId = await this.magicStoneNFT.tokenOfOwnerByIndex(alice, parseInt(magicStones.toString())-1);
        // await this.cryptoShibaController.setAutoFight(tokenId, 0, { from : alice});
        // result = await this.cryptoShibaController.getAutoFightResults(tokenId, {from: alice});
        // console.log(result.logs[0].args);

        // result = await this.cryptoShibaNFT.fillOrder(tokenId, bob, {from: admin});
        // console.log('////////////////////////');
        // // result = await this.cryptoShibaNFT.orders(alice);
        // // result = await this.cryptoShibaNFT.tokenSaleOfOwnerByIndex(alice, 0);
        // // result = await this.cryptoShibaNFT.balanceOf(alice);
        // // result = await this.cryptoShibaNFT.balanceOf(alice);
        // // console.log('result', result.toString());
        // // result = await this.marketController.getShibasInfo([1]);
        // // console.log(result);
        // // result = await this.cryptoShibaNFT.balanceOf(admin);
        // // console.log('result', result.toString());
    })
})