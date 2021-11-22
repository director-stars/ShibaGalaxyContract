const CryptoShibaController = artifacts.require("CryptoShibaController")
module.exports = async function (deployer) {
  await deployer.deploy(CryptoShibaController);
};