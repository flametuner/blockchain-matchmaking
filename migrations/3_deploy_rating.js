const TicTacToe = artifacts.require("TicTacToe");

const EloRating = artifacts.require("EloRating");

module.exports = async function (deployer) {
    tictactoe = await TicTacToe.deployed()
    const eloRating = await deployer.deploy(EloRating, tictactoe.address)
    await tictactoe.updateRatingSystem(eloRating.address)
};

// https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations
