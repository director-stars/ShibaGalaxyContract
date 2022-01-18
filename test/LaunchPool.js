const ForceSend = artifacts.require('ForceSend');

const LaunchPool = artifacts.require('LaunchPool')
const ether = require('openzeppelin-test-helpers/src/ether');
const shibaGalaxyABI = require('./abi/shibaGalaxy');

const shibaGalaxyAddress = '0x7420d2Bc1f8efB491D67Ee860DF1D35fe49ffb8C';
const shibaGalaxyContract = new web3.eth.Contract(shibaGalaxyABI, shibaGalaxyAddress);
const shibaGalaxyOwner1 = '0x67926b0C4753c42b31289C035F8A656D800cD9e7';
const shibaGalaxyOwner2 = '0xb35869eCfB96c27493cA281133edd911e479d0D9';
const shibaGalaxyOwner3 = '0xe2Ab69E47763E80116B28a66C7860eF030D18B6e';
const shibaGalaxyOwner4 = '0xcC4a5788fF820B44dBfd19C6D94Ec6B59b55469E';
contract('test LaunchPool', async([alice, bob, admin, dev, minter]) => {

    before(async () => {
        this.launchPool = await LaunchPool.new({
            from: alice
        });
        await web3.eth.sendTransaction({
            from: admin, 
            to: shibaGalaxyOwner1,
            value: ether('1')
        });
        await web3.eth.sendTransaction({
            from: admin, 
            to: shibaGalaxyOwner2,
            value: ether('1')
        });
        await web3.eth.sendTransaction({
            from: admin, 
            to: shibaGalaxyOwner3,
            value: ether('1')
        });
        await web3.eth.sendTransaction({
            from: admin, 
            to: shibaGalaxyOwner4,
            value: ether('1')
        });
        await web3.eth.sendTransaction({
            from: admin, 
            to: this.launchPool.address,
            value: ether('50')
        });
    });

    it('test', async() => {
        console.log('launchpool: ', this.launchPool.address);
        await this.launchPool.startRound("20000000000000000000", {
            from: alice
        });
        let round = await this.launchPool.round();
        console.log("round: ", round.toString());
        await shibaGalaxyContract.methods.approve(this.launchPool.address, "20000000000000000000").send({ from : shibaGalaxyOwner1});
        await shibaGalaxyContract.methods.approve(this.launchPool.address, "20000000000000000000").send({ from : shibaGalaxyOwner2});
        await shibaGalaxyContract.methods.approve(this.launchPool.address, "20000000000000000000").send({ from : shibaGalaxyOwner3});
        await shibaGalaxyContract.methods.approve(this.launchPool.address, "20000000000000000000").send({ from : shibaGalaxyOwner4});
        
        await this.launchPool.deposit(shibaGalaxyOwner1, "100000000000000",{
            from: shibaGalaxyOwner1
        })
        await this.launchPool.deposit(shibaGalaxyOwner2, "1000003403033030",{
            from: shibaGalaxyOwner2
        })
        await this.launchPool.deposit(shibaGalaxyOwner3, "2382893443410000",{
            from: shibaGalaxyOwner3
        })
        await this.launchPool.deposit(shibaGalaxyOwner4, "38998489410000",{
            from: shibaGalaxyOwner4
        })
        await this.launchPool.withdrawTokenForCurrentRound(
            shibaGalaxyOwner1,
            "2029293",
            {
                from: shibaGalaxyOwner1
            }
        );
        await this.launchPool.deposit(
            shibaGalaxyOwner4,
            "29823338389298",
            {
                from: shibaGalaxyOwner4
            }
        );
        // await this.launchPool.claimAndWithdrawForOldRound(shibaGalaxyOwner3, {
        //     from: shibaGalaxyOwner3
        // });
        await this.launchPool.endRound({
            from: alice
        })
        let balance = await web3.eth.getBalance(shibaGalaxyOwner4);
        console.log('balance: ', balance.toString());
        await this.launchPool.claimAndWithdrawForOldRound(shibaGalaxyOwner4, {
            from: shibaGalaxyOwner4
        });
        balance = await web3.eth.getBalance(shibaGalaxyOwner4);
        console.log('balance: ', balance.toString());
        await this.launchPool.startRound("10000000000000000000", {
            from: alice
        });
        await this.launchPool.claimAndWithdrawForOldRound(shibaGalaxyOwner1, {
            from: shibaGalaxyOwner1
        });
    })
})

// ganache-cli -f https://bsc.getblock.io/mainnet/?api_key=3c0eb929-72ad-46e3-8c37-fab3d4587e64 -m "hidden moral pulp timber famous opinion melt any praise keen tissue aware" -l 100000000 -i 1 -u 0x7420d2Bc1f8efB491D67Ee860DF1D35fe49ffb8C -u 0x67926b0C4753c42b31289C035F8A656D800cD9e7 -u 0x9c9cb6d14ea3A42f97613C74EC79F364b3041768 -u 0xb35869eCfB96c27493cA281133edd911e479d0D9 -u 0xe2Ab69E47763E80116B28a66C7860eF030D18B6e -u 0xcC4a5788fF820B44dBfd19C6D94Ec6B59b55469E --allowUnlimitedContractSize