const fs = require("fs");
const path = require("path");

const artifactPath = path.resolve(__dirname, "../artifacts/contracts/SecureVault.sol/SecureVault.json");
const outputPath = path.resolve(__dirname, "../abi/SecureVault.json");

const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

fs.writeFileSync(outputPath, JSON.stringify(artifact.abi, null, 2));
console.log("✅ ABI extracted to frontend/abi/SecureVault.json");
