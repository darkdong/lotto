const Casino = artifacts.require("Casino")
const Utils = require("./utils.js")
// console.log(web3)
console.log('web3.version', web3.version.api)

contract('Casino', async (accounts) => {
    it("game", async () => {
        const casino = await Casino.deployed()
        const dealer = accounts[1]
        const player = accounts[2]

        const gameId = '12xy'
        const number = 3
        const secret = web3.sha3('xyz')
        const encryptedNumber = keccak256(number, secret)

        await casino.create(gameId, encryptedNumber, web3.toWei('1', 'ether'), 5, 300, 300, {
            from: dealer,
            value: web3.toWei('5', 'ether')
        })
        await casino.guess(gameId, 3, {
            from: player,
            value: web3.toWei('1', 'ether')
        })
        const result = await casino.reveal(gameId, number, secret, {
            from: dealer,
        })
        for (log of result.logs) {
            if (log.event === "GameEnded") {
                const args = log.args
                console.log(log.event, args.gameId, args.winner, Utils.bn2ether(args.value));
            }
        }

        await casino.withdraw({
            from: dealer
        })
        await casino.withdraw({
            from: player
        })
        await casino.withdraw({
            from: accounts[8]
        })

        // Utils.timeElapse(86400 * 100)
    })
})

function keccak256(...args) {
    args = args.map(arg => {
        if (typeof arg === 'string') {
            if (arg.substring(0, 2) === '0x') {
                return arg.slice(2)
            } else {
                return web3.toHex(arg).slice(2)
            }
        }

        if (typeof arg === 'number') {
            return web3.padLeft((arg).toString(16), 64, 0)
        } else {
            return ''
        }
    })

    args = args.join('')

    return web3.sha3(args, {
        encoding: 'hex'
    })
}