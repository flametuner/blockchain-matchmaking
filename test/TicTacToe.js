const truffleAssert = require('truffle-assertions');
const TicTacToe = artifacts.require("TicTacToe");
const EloRating = artifacts.require("EloRating");
const signHelper = require("./helpers/signatureHelper");


contract("TicTacToe", async (accounts) => {
    context("Normal flow", function () {
        let gameContract;
        let eloRating;
        before(async () => {
            gameContract = await TicTacToe.deployed();
            eloRating = await EloRating.deployed();
        });

        it("Should create a new game", async () => {
            const creator = accounts[0];
            const challenged = accounts[1];
            const creatorNonce = (await eloRating.getPlayerNonce(creator)).valueOf();
            const challengedNonce = (await eloRating.getPlayerNonce(challenged)).valueOf();

            const match = {
                playerA: {
                    addr: creator,
                    nonce: creatorNonce
                },
                playerB: {
                    addr: challenged,
                    nonce: challengedNonce
                },
                timestamp: Math.floor(new Date().getTime() / 1000)
            }

            const hash = signHelper.hashMatch(match);



            const hashToSign = signHelper.hashToSign(hash);

            const contractHash = (await eloRating.hashMatch(match)).valueOf();
            assert.equal(hash, contractHash);

            const contractHashToSign = (await eloRating.hashToSign(hash)).valueOf();
            assert.equal(hash, contractHash);

            const sigpA = await signHelper.generateSignature(hash, creator);
            const sigpB = await signHelper.generateSignature(hash, challenged);
            console.log({hash, creator, challenged})

            const tx = await gameContract.newGame(match, sigpA, sigpB, { from: creator });

            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) => ev.creator === creator)
        });
        // it("Should join the game", async () => {
        //     const creator = accounts[0];
        //     const tx = await gameContract.newGame({ from: creator });

        //     truffleAssert.eventEmitted(tx, 'GameCreated', (ev) =>
        //         ev.creator === creator
        //     )
        // });
        // https://www.trufflesuite.com/docs/truffle/reference/truffle-commands
    });
})
