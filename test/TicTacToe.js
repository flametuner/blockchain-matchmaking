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
            const nonceA = (await eloRating.getPlayerNonce(pA)).valueOf().toString();
            const nonceB = (await eloRating.getPlayerNonce(pB)).valueOf().toString();
            const match = generator.generateMatchWithNonces(pA, nonceA, pB, nonceB);
            const hash = signHelper.hashMatch(match);
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);

            const tx = await gameContract.newGame(match, sigpA, sigpB, { from: pA });

            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) => ev.creator === pA)
        });
        it("Should create a new game 2", async () => {
            const pA = accounts[0];
            const pB = accounts[1];
            const nonceA = (await eloRating.getPlayerNonce(pA)).valueOf().toString();
            const nonceB = (await eloRating.getPlayerNonce(pB)).valueOf().toString();
            console.log("A1")
            // console.log(pA, pB, nonceA, nonceB);
            const match = generator.generateMatchWithNonces(pA, nonceA, pB, nonceB);
            console.log(match)
            const library = await GameLibrary.deployed();

            const hash = signHelper.hashMatch(match);
            const contractHash = (await library.hashMatch(match.playerA, match.nonceA, match.playerB, match.nonceB, match.timestamp)).valueOf();
            console.log(hash)
            console.log(contractHash)
            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);
            
            const hashToSign = signHelper.hashToSign(hash);
            const sigAddrA = (await library._ecrecover(hashToSign, sigpA.v, sigpA.r, sigpA.s)).valueOf();

            console.log(pA)
            console.log(sigAddrA)

            const sigAddrB = (await library._ecrecover(hashToSign, sigpB.v, sigpB.r, sigpB.s)).valueOf();
            console.log(pB)
            console.log(sigAddrB)

            const valid = (await library.validateMatch(
                match.playerA, match.nonceA, match.playerB, match.nonceB, match.timestamp,
                sigpA.v, sigpA.r, sigpA.s,
                sigpB.v, sigpB.r, sigpB.s,
            )).valueOf();
            console.log(valid)


            const tx = await gameContract.newGame(match, sigpB, sigpB, { from: pA });
            console.log("A2")
            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) => ev.creator === pA)
        });

        // https://www.trufflesuite.com/docs/truffle/reference/truffle-commands
    });
    context("Game moves", function () {
        let gameContract;
        let eloRating;
        let match;
        let hash;
        before(async () => {
            gameContract = await TicTacToe.deployed();
            eloRating = await EloRating.deployed();
            const pA = accounts[0];
            const pB = accounts[1];
            const nonceA = (await eloRating.getPlayerNonce(pA)).valueOf().toString();
            const nonceB = (await eloRating.getPlayerNonce(pB)).valueOf().toString();

            match = generator.generateMatchWithNonces(pA, nonceA, pB, nonceB);

            hash = signHelper.hashMatch(match);

            const sigpA = await signHelper.generateSignature(hash, pA);
            const sigpB = await signHelper.generateSignature(hash, pB);

            await gameContract.newGame(match, sigpA, sigpB, { from: pA });
        });

        it("Player A should make a move", async () => {
            const pA = accounts[0];
            // const pB = accounts[1];
            const tx = await gameContract.makeMove(match, hash, 0, 0, { from: pA });

            truffleAssert.eventEmitted(tx, 'PlayerMadeMove', (ev) =>
                ev.player === pA
            );
        });
    });
})
