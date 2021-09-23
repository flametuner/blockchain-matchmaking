const truffleAssert = require('truffle-assertions');
const TicTacToe = artifacts.require("TicTacToe");



contract("TicTacToe", async (accounts) => {
    context("Normal flow", function () {
        let gameContract;

        before(async () => {
            gameContract = await TicTacToe.deployed();
        });

        it("Should create a new game", async () => {
            const creator = accounts[0];
            const tx = await gameContract.newGame({ from: creator });

            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) =>
                ev.creator === creator
            )
        });
        it("Should join the game", async () => {
            const creator = accounts[0];
            const tx = await gameContract.newGame({ from: creator });

            truffleAssert.eventEmitted(tx, 'GameCreated', (ev) =>
                ev.creator === creator
            )
        });
        // https://www.trufflesuite.com/docs/truffle/reference/truffle-commands
    });
})