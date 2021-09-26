const GameLibrary = artifacts.require("GameLibrary");

module.exports = function (deployer) {
  deployer.deploy(GameLibrary);
};
