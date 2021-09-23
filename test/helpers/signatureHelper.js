async function generateSignature(hash, address) {
    let sig = await web3.eth.sign(hash, address);
    console.log(sig)
    if (sig.slice(0, 2) === "0x") sig = sig.substr(2);
    // var r = "0x" + sig.substr(0, 64);
    // var s = "0x" + sig.substr(64, 64);
    // var v = web3.utils.toDecimal(sig.substr(128, 2)) + 27;
    const r = '0x' + sig.slice(0, 64)
    const s = '0x' + sig.slice(64, 128)
    const v = web3.utils.toDecimal('0x' + sig.slice(128, 130)) + 27
    var ret = { v, r, s };
    console.log(ret)
    return ret;
}

function hashMatch(_match) {
    return web3.utils.soliditySha3(
        _match.playerA.addr,
        _match.playerA.nonce,
        _match.playerB.addr,
        _match.playerB.nonce,
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