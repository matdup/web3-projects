"use client";
import { useEffect, useState } from "react";
import { getContract } from "../../lib/ethers";
import { ethers } from "ethers";
import { INVESTOR_ROLE, AUDITOR_ROLE } from "../../lib/roles";

export default function AdminPage() {
  const [depositLimit, setDepositLimit] = useState("");
  const [roleAddress, setRoleAddress] = useState("");
  const [roleType, setRoleType] = useState("INVESTOR_ROLE");
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    const fetchStatus = async () => {
      const contract = await getContract();
      setPaused(await contract.paused());
    };
    fetchStatus();
  }, []);

  const pause = async () => { await (await (await getContract()).pause()).wait(); alert("Vault paused"); window.location.reload(); };
  const unpause = async () => { await (await (await getContract()).unpause()).wait(); alert("Vault unpaused"); window.location.reload(); };
  const updateLimit = async () => { await (await (await getContract()).setDepositLimit(ethers.parseEther(depositLimit))).wait(); alert("Limit updated"); };
  const grantRole = async () => {
    const role = roleType === "INVESTOR_ROLE" ? INVESTOR_ROLE : AUDITOR_ROLE;
    await (await (await getContract()).grantVaultRole(role, roleAddress)).wait();
    alert("Role granted!");
  };
  const revokeRole = async () => {
    const role = roleType === "INVESTOR_ROLE" ? INVESTOR_ROLE : AUDITOR_ROLE;
    await (await (await getContract()).revokeVaultRole(role, roleAddress)).wait();
    alert("Role revoked!");
  };

  return (
    <div className="max-w-xl mx-auto py-10 space-y-6">
      <h1 className="text-3xl font-bold">🛠 Admin Panel</h1>
      <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow space-y-4">
        <p>Status: {paused ? "⏸️ Paused" : "✅ Active"}</p>
        <button onClick={pause} className="w-full bg-orange-500 text-white py-2 rounded">Pause</button>
        <button onClick={unpause} className="w-full bg-green-600 text-white py-2 rounded">Unpause</button>

        <input className="w-full p-2 border rounded" placeholder="New Deposit Limit"
          value={depositLimit} onChange={(e) => setDepositLimit(e.target.value)} />
        <button onClick={updateLimit} className="w-full bg-purple-600 text-white py-2 rounded">Update Limit</button>

        <select className="w-full p-2 border rounded" value={roleType} onChange={(e) => setRoleType(e.target.value)}>
          <option value="INVESTOR_ROLE">Investor</option>
          <option value="AUDITOR_ROLE">Auditor</option>
        </select>
        <input className="w-full p-2 border rounded" placeholder="Address" value={roleAddress} onChange={(e) => setRoleAddress(e.target.value)} />
        <div className="flex gap-2">
          <button onClick={grantRole} className="flex-1 bg-blue-600 text-white py-2 rounded">Grant</button>
          <button onClick={revokeRole} className="flex-1 bg-red-600 text-white py-2 rounded">Revoke</button>
        </div>
      </div>
    </div>
  );
}