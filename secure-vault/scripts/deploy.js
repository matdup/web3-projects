// scripts/deploy.js

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  const initialDepositLimit = ethers.utils.parseEther("1000");
  const tokenAddress = "<TOKEN_ADDRESS_HERE>"; // Replace with actual ERC-20 token address

  const SecureVault = await ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(tokenAddress, initialDepositLimit);

  await vault.deployed();
  console.log("SecureVault deployed to:", vault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
