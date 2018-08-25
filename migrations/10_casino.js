const Casino = artifacts.require("Casino")

module.exports = (deployer) => {
    deployer.then(async () => {
        await deployer.deploy(Casino)
    })
}