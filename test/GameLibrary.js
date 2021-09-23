const GameLibrary = artifacts.require("GameLibrary");
const signHelper = require("./helpers/signatureHelper");

function generateRandomMatch(pA, pB) {
    return {
        playerA: {
            addr: pA,
            nonce: Math.floor(Math.random() * 10)
        },
        playerB: {
            addr: pB,
            nonce: Math.floor(Math.random() * 10)
        },
        timestamp: Math.floor(new Date().getTime() / 1000)
    }
}

contract('GameLibrary', async (accounts) => {
    context('Signer Helper', () => {
        let library;
        before(async () => {
            library = await GameLibrary.deployed();
        });

        it('Should return the correct Match hash', () => {
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generateRandomMatch(pA, pB);

            const hash = signHelper.hashMatch(match);
            const contractHash = (await eloRating.hashMatch(match)).valueOf();
            assert.equal(hash, contractHash);
        });

        it('Should return the correct Match hashToSign', () => {
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generateRandomMatch(pA, pB);

            const hash = signHelper.hashMatch(match);

            const hashToSign = signHelper.hashToSign(hash);
            const contractHashToSign = (await eloRating.hashToSign(hash)).valueOf();
            assert.equal(hashToSign, contractHashToSign);
        });
    });
});