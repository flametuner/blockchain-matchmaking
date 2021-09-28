const truffleAssert = require('truffle-assertions');
var truffleEvent = require('truffle-events');
const generator = require("./helpers/generators");
const signHelper = require("./helpers/signatureHelper");
const TicTacToe = artifacts.require("TicTacToe");
const EloRating = artifacts.require('EloRating');



contract("EloRating", async (accounts) => {
    context("Game creation and Elo Update", function () {
        const pA = accounts[0];
        const pB = accounts[1];
        let gameContract;
        let eloRating;
        let gameId; 

        before(async () => {
            gameContract = await TicTacToe.deployed();
            eloRating = await EloRating.deployed();
        });

        it("Should create a new match", async () => {
            const match = generator.generateMatch(pA, pB);
            const hash = signHelper.hashMatch(match);
            gameId = signHelper.hashToSign(hash);
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);

            const before = (await eloRating.matches.call(gameId));
            assert.equal(before.state, 0); // State Not Started

            await gameContract.newGame(match, sigpA, sigpB, { from: pA });

            const after = (await eloRating.matches.call(gameId));
            assert.equal(after.state, 1); // State Started

        });
        it("Should update elo for player A and B", async () => {

            const eloBeforeA = (await eloRating.getPlayerRating.call(pA));
            const eloBeforeB = (await eloRating.getPlayerRating.call(pB));

            await gameContract.makeMove(gameId, 0, 0, { from: pA });
            await gameContract.makeMove(gameId, 0, 1, { from: pB });
            await gameContract.makeMove(gameId, 1, 0, { from: pA });
            await gameContract.makeMove(gameId, 1, 1, { from: pB });
            await gameContract.makeMove(gameId, 2, 0, { from: pA });

            const eloAfterA = (await eloRating.getPlayerRating.call(pA));
            const eloAfterB = (await eloRating.getPlayerRating.call(pB));

            assert.equal(eloAfterA > eloBeforeA, true); // Player A won
            assert.equal(eloAfterB < eloBeforeB, true); // Player B lost
        });
        // https://www.trufflesuite.com/docs/truffle/reference/truffle-commands
    });
})