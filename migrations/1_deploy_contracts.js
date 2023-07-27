// const Escrow_Factory = artifacts.require('Escrow_Factory.sol');
const TimelockVaultFactory = artifacts.require('TimelockVaultFactory.sol');
// const storage = artifacts.require('Storage.sol');
// const Auto_Transfer = artifacts.require('Auto_Transfer.sol');


module.exports = function (deployer) {
    deployer.deploy(TimelockVaultFactory);
    // deployer.deploy(storage);
}