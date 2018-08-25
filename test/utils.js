function timeElapse(seconds) {
    web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [seconds],
        id: 0
    })
    web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_mine",
        params: [],
        id: 0
    })
}

function bn2ether(bn) {
    return web3.fromWei(bn.toString(), 'ether')
}

exports.timeElapse = timeElapse
exports.bn2ether = bn2ether