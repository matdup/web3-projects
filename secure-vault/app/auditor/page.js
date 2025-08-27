"use client";
import { useState } from "react";
import { getContract } from "../../lib/ethers";
import { ethers } from "ethers";

export default function AuditorPage() {
  const [address, setAddress] = useState("");
  const [balance, setBalance] = useState("");

  const checkBalance = async () => {
    const contract = await getContract();
    const bal = await contract.viewBalance(address);
    setBalance(ethers.formatEther(bal));
  };

  return (
    <div className="max-w-xl mx-auto py-10">
      <h1 className="text-3xl font-bold mb-6">🔍 Auditor Tools</h1>
      <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-4">
        <input className="w-full p-2 border rounded" placeholder="Address to check"
          value={address} onChange={(e) => setAddress(e.target.value)} />
        <button onClick={checkBalance} className="w-full bg-indigo-600 text-white py-2 rounded">
          View Balance
        </button>
        {balance && <p>Balance: <b>{balance} tokens</b></p>}
      </div>
    </div>
  );
}