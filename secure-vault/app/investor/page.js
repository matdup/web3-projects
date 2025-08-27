"use client";
import { useEffect, useState } from "react";
import { getContract, getSigner } from "../../lib/ethers";
import { ethers } from "ethers";

export default function InvestorPage() {
  const [balance, setBalance] = useState("0");
  const [depositLimit, setDepositLimit] = useState("0");
  const [depositAmount, setDepositAmount] = useState("");
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      const signer = await getSigner();
      const account = await signer.getAddress();
      const contract = await getContract();
      setBalance(ethers.formatEther(await contract.balances(account)));
      setDepositLimit(ethers.formatEther(await contract.depositLimitPerAddress()));
      setPaused(await contract.paused());
    };
    fetchData();
  }, []);

  const deposit = async () => {
    const contract = await getContract();
    await (await contract.deposit(ethers.parseEther(depositAmount))).wait();
    alert("Deposit successful!");
    window.location.reload();
  };

  const withdraw = async () => {
    const contract = await getContract();
    await (await contract.withdraw(ethers.parseEther(withdrawAmount))).wait();
    alert("Withdraw successful!");
    window.location.reload();
  };

  const emergencyWithdraw = async () => {
    const contract = await getContract();
    await (await contract.emergencyWithdraw()).wait();
    alert("Emergency withdrawal successful!");
    window.location.reload();
  };

  return (
    <div className="max-w-xl mx-auto py-10">
      <h1 className="text-3xl font-bold mb-6">💰 Investor Panel</h1>
      <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-4">
        <p><b>Your Balance:</b> {balance} tokens</p>
        <p><b>Deposit Limit:</b> {depositLimit} tokens</p>
        <p><b>Status:</b> {paused ? "⏸️ Paused" : "✅ Active"}</p>

        {!paused && (
          <>
            <input className="w-full p-2 border rounded" placeholder="Deposit amount"
              value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} />
            <button onClick={deposit} className="w-full bg-blue-600 text-white py-2 rounded">Deposit</button>

            <input className="w-full p-2 border rounded mt-3" placeholder="Withdraw amount"
              value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} />
            <button onClick={withdraw} className="w-full bg-red-600 text-white py-2 rounded">Withdraw</button>
          </>
        )}

        {paused && (
          <button onClick={emergencyWithdraw} className="w-full bg-yellow-500 text-white py-2 rounded">
            ⚠️ Emergency Withdraw
          </button>
        )}
      </div>
    </div>
  );
}