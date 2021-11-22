const CryptoShibaNFT = artifacts.require("CryptoShibaNFT")
module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(CryptoShibaNFT, "CryptoShibaNFT", "CryptoShibaNFT", accounts[0], '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56');
};