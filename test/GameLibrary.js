const GameLibrary = artifacts.require("GameLibrary");
const signHelper = require("./helpers/signatureHelper");
const generator = require("./helpers/generators");


contract('GameLibrary', async (accounts) => {
    context('Signer Helper', function () {
        let library;
        before(async () => {
            library = await GameLibrary.deployed();
        });

        it('Should return the correct Match hash', async () => {
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generator.generateMatch(pA, pB);

            const hash = signHelper.hashMatch(match);
            const contractHash = (await library.hashMatch(match.playerA, match.playerB, match.nonce)).valueOf();

            assert.equal(hash, contractHash);
        });

        it('Should return the correct Match hashToSign', async () => {
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generator.generateMatch(pA, pB);

            const hash = signHelper.hashMatch(match);

            const hashToSign = signHelper.hashToSign(hash);
            const contractHashToSign = (await library.hashToSign(hash)).valueOf();
            assert.equal(hashToSign, contractHashToSign);
        });

        it('Should validate the signatures', async () => {
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generator.generateMatch(pA, pB);
            const hash = signHelper.hashMatch(match);
            const hashToSign = signHelper.hashToSign(hash);

            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigAddrA = (await library._ecrecover(hashToSign, sigpA.v, sigpA.r, sigpA.s)).valueOf();

            assert.equal(sigAddrA, pA);

            const sigpB = await signHelper.generateSignature(hash, pB);
            const sigAddrB = (await library._ecrecover(hashToSign, sigpB.v, sigpB.r, sigpB.s)).valueOf();

            assert.equal(sigAddrB, pB);

            const valid = (await library.validateMatch(
                match.playerA, match.playerB, match.nonce,
                sigpA.v, sigpA.r, sigpA.s,
                sigpB.v, sigpB.r, sigpB.s,
            )).valueOf();

            assert.equal(valid, true);
        });
    });
});