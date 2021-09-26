const TicTacToe = artifacts.require("TicTacToe");
const GameLibrary = artifacts.require("GameLibrary");

module.exports = async function (deployer) {
  await deployer.link(GameLibrary, TicTacToe);
  await deployer.deploy(TicTacToe);
};
