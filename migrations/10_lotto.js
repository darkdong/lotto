const Lotto = artifacts.require("Lotto")

module.exports = (deployer) => {
    deployer.then(async () => {
        await deployer.deploy(Lotto)
    })
}