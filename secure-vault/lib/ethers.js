import { ethers, Contract } from "ethers";
import vaultAbi from "../abi/SecureVault.json";

const VAULT_ADDRESS = "<YOUR_DEPLOYED_CONTRACT_ADDRESS>";

export const getProvider = () => new ethers.BrowserProvider(window.ethereum);
export const getSigner = async () => (await getProvider()).getSigner();
export const getContract = async () => new Contract(VAULT_ADDRESS, vaultAbi, await getSigner());