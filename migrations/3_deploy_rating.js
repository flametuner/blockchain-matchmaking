const TicTacToe = artifacts.require("TicTacToe");

const EloRating = artifacts.require("EloRating");

module.exports = async function (deployer) {
    tictactoe = await TicTacToe.deployed()
    await deployer.deploy(EloRating, tictactoe.address)
};

// https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations
