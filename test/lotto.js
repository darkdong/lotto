const Lotto = artifacts.require("Lotto")

contract('Lotto', async (accounts) => {
    it("lock users", async () => {
        const lotto = await Lotto.deployed()
        console.log(lotto)  
    })
})  