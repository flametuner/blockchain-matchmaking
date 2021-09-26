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
            // const nonceA = (await eloRating.getPlayerNonce(pA)).valueOf().toString();
            // const nonceB = (await eloRating.getPlayerNonce(pB)).valueOf().toString();
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
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);
            gameId = await gameContract.newGame.call(match, sigpA, sigpB, { from: pA });
            console.log(gameId);
        });

        it("Player A should make a move", async () => {
            const pA = accounts[0];
            // const pB = accounts[1];
            const tx = await gameContract.makeMove(gameId, 0, 0, { from: pA });
            console.log(tx)
            truffleAssert.eventEmitted(tx, 'PlayerMadeMove', (ev) =>
                ev.player === pA
            );
        });
    });
})
