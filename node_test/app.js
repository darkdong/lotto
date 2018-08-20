const Web3 = require('web3')
// const provider = new Web3.providers.WebsocketProvider('ws://127.0.0.1:8546') // geth
const provider = new Web3.providers.WebsocketProvider('ws://127.0.0.1:7545') // ganache
// const provider = new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/ws')
const web3 = new Web3(provider)
console.log(web3)

// String.prototype.toEther = function () {
//     return web3.utils.fromWei(String(this), 'ether')
// }

test()

async function test() {
    const networkId = await web3.eth.net.getId()
    const gasPrice = await web3.eth.getGasPrice()
    console.log('version:', web3.version, 'networkID:', networkId, 'gasPrice:', gasPrice)
    const accounts = await web3.eth.getAccounts()
    const account = accounts.length === 0 ? '0x55d95463A92f270c5b5980A69C5fA0B3767Af12E' : accounts[0]
    
    const file = '/Users/dark/work/wallet.txt'
    const password = '123456'
    // web3.eth.accounts.wallet.add('Private Key')
    // await saveWallet(file, password)
    await loadWallet(file, password)

    const balance = await web3.eth.getBalance(account)
    console.log('balance:', web3.utils.fromWei(balance, 'ether'), 'ETH')

    // const iost = await newContract('blockchain/build/contracts/IOSToken.json')
    // const locker = await newContract('blockchain/build/contracts/IostPowerLocker.json')

    // const balance = await iost.methods.balanceOf(account).call({
    //     from: account
    // })
    // console.log('balance', balance.toEther())

    // console.log('get all past events...')
    // const pastEvents = await iost.getPastEvents('allEvents', {
    //     fromBlock: 0,
    // })
    // for (event of pastEvents) {
    //     console.log('past event', event.event, event.returnValues)
    // }

    // console.log('watching events...')
    // await iost.events.allEvents((error, event) => {
    //     console.log('watching event', event.event, event.returnValues)
    // })

    // console.log('send transactions...')
    // let tx, receipt
    // tx = iost.methods.approve(locker.options.address, web3.utils.toWei('10000', 'ether'))
    // receipt = await sendTransaction(tx)
    // console.log(receipt)

    // tx = locker.methods.lock(web3.utils.toWei('10000', 'ether'), 0)
    // receipt = await sendTransaction(tx)
    // console.log(receipt)
}

async function sendTransaction(tx, gas = 1230000) {
    return await web3.eth.sendTransaction({
        data: tx.encodeABI(),
        from: 0,
        to: tx._parent.options.address,
        gas: gas
    })
}

async function newContract(file) {
    const fs = require('mz/fs')
    const data = await fs.readFile(file)
    const json = await JSON.parse(data)
    const abi = json['abi']
    const networkId = await web3.eth.net.getId()
    const address = json['networks'][networkId]['address']
    return new web3.eth.Contract(
        abi,
        address
    )
}

async function loadWallet(file, password) {
    const fs = require('mz/fs')
    const data = await fs.readFile(file)
    const json = await JSON.parse(data)
    web3.eth.accounts.wallet.decrypt(json, password)
}

async function saveWallet(file, password) {
    const ksObj = web3.eth.accounts.wallet.encrypt(password)
    const ksString = await JSON.stringify(ksObj)
    const fs = require('mz/fs')
    await fs.writeFile(file, ksString)
}