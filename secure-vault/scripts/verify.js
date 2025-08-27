// scripts/verify.js

const { run } = require("hardhat");

async function main() {
  const contractAddress = "<DEPLOYED_CONTRACT_ADDRESS>"; // Replace with deployed address
  const tokenAddress = "<ERC20_TOKEN_ADDRESS>"; // Replace with constructor argument
  const depositLimit = ethers.utils.parseEther("1000");

  await run("verify:verify", {
    address: contractAddress,
    constructorArguments: [tokenAddress, depositLimit],
  });
}

main()
  .then(() => console.log("Verification request sent."))
  .catch((error) => {
    console.error("Verification failed:", error);
    process.exit(1);
  });
