const util = require('ethereumjs-util')

async function generateSignature(hash, address) {
    let sig = await web3.eth.sign(hash, address);

    const res = util.fromRpcSig(sig);
    return res;
}

function hashMatch(_match) {
    return web3.utils.soliditySha3(
        _match.playerA,
        _match.nonceA,
        _match.playerB,
        _match.nonceB,
        _match.timestamp
    );
}

function hashToSign(_hash) {
    return web3.utils.soliditySha3("\x19Ethereum Signed Message:\n32", _hash);
}

module.exports = {
    generateSignature,
    hashMatch,
    hashToSign,
};