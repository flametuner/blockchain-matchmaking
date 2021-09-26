function generateRandomMatch(pA, pB) {
    return {
        playerA: pA,
        nonceA: Math.floor(Math.random() * 10),
        playerB: pB,
        nonceB: Math.floor(Math.random() * 10),
        timestamp: Math.floor(new Date().getTime() / 1000)
    }
}

module.exports = {
    generateRandomMatch
}