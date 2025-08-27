/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  paths: {
    sources: "./contracts",
    tests: "./test/hardhat",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
