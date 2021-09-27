let gameNonce = 0;


function generateMatch(pA, pB) {
    return {
        playerA: pA,
        playerB: pB,
        nonce: gameNonce++
    }
}

module.exports = {
    generateMatch
}