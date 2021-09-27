const TicTacToe = artifacts.require("TicTacToe");
const GameLibrary = artifacts.require("GameLibrary");
const EloRating = artifacts.require("EloRating");

module.exports = async function (deployer) {
    await deployer.link(GameLibrary, TicTacToe);
    tictactoe = await TicTacToe.deployed()
    const eloRating = await deployer.deploy(EloRating, tictactoe.address)
    await tictactoe.updateRatingSystem(eloRating.address)
};

// https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations
