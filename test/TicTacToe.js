const truffleAssert = require('truffle-assertions');
const TicTacToe = artifacts.require("TicTacToe");
const EloRating = artifacts.require("EloRating");
const GameLibrary = artifacts.require("GameLibrary");
const signHelper = require("./helpers/signatureHelper");
const generator = require("./helpers/generators");

contract("TicTacToe", async (accounts) => {
    context("Game creation", function () {
        let gameContract;
        let eloRating;
        before(async () => {
            gameContract = await TicTacToe.deployed();
            eloRating = await EloRating.deployed();
        });

        it("Should create a new game", async () => {
            const pA = accounts[0];
            const pB = accounts[1];
            
            const match = generator.generateMatch(pA, pB);
            const hash = signHelper.hashMatch(match);
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);

            const tx = await gameContract.newGame(match, sigpA, sigpB, { from: pA });

            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) => ev.creator === pA)
        });

        // https://www.trufflesuite.com/docs/truffle/reference/truffle-commands
    });
    context("Game moves", function () {
        let gameContract;
        let eloRating;
        let gameId;
        before(async () => {
            gameContract = await TicTacToe.deployed();
            eloRating = await EloRating.deployed();
            const pA = accounts[0];
            const pB = accounts[1];

            const match = generator.generateMatch(pA, pB);
            const hash = signHelper.hashMatch(match);
            gameId = signHelper.hashToSign(hash);
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);
            await gameContract.newGame(match, sigpA, sigpB, { from: pA });
            // console.log(gameId);
        });

        it("Player A should make a move", async () => {
            const pA = accounts[0];
            // const pB = accounts[1];
            const tx = await gameContract.makeMove(gameId, 0, 0, { from: pA });

            truffleAssert.eventEmitted(tx, 'PlayerMadeMove', (ev) =>
                ev.player === pA
            );
        });

        it("Player A should not make a move", async () => {
            const pA = accounts[0];
            // const pB = accounts[1];
            const tx = await gameContract.makeMove.call(gameId, 0, 1, { from: pA });

            assert.equal(tx.reason, "It is not your turn.");
        });
        it("Player B should make a move", async () => {
            // const pA = accounts[0];
            const pB = accounts[1];
            const tx = await gameContract.makeMove(gameId, 0, 1, { from: pB });

            truffleAssert.eventEmitted(tx, 'PlayerMadeMove', (ev) =>
                ev.player === pB
            );
        });
        it("Player should not use existing coords", async () => {
            const pA = accounts[0];
            // const pB = accounts[1];
            const tx = await gameContract.makeMove.call(gameId, 0, 0, { from: pA });

            assert.equal(tx.reason, "There is already a mark at the given coordinates.");
        });
        it("Player B should win", async () => {
            const pA = accounts[0];
            const pB = accounts[1];
            await gameContract.makeMove(gameId, 1, 0, { from: pA });
            await gameContract.makeMove(gameId, 1, 1, { from: pB });
            await gameContract.makeMove(gameId, 0, 2, { from: pA });
            const tx = await gameContract.makeMove(gameId, 2, 1, { from: pB });


            truffleAssert.eventEmitted(tx, 'GameOver', (ev) =>
                ev.winner == 2 // PLayer B
            );
        });
    });
})
