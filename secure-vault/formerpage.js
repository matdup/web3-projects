
"use client";
 
import { useEffect, useState } from "react";
import { ethers, Contract } from "ethers";
import vaultAbi from "../abi/SecureVault.json";

const VAULT_ADDRESS = "<YOUR_DEPLOYED_CONTRACT_ADDRESS>";
const DESIRED_CHAIN_ID = "0x1"; // Ethereum Mainnet (change to your chain ID)

export default function Dashboard() {
  // Web3 state
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();
  const [contract, setContract] = useState();
  const [account, setAccount] = useState();

  // App state
  const [depositAmount, setDepositAmount] = useState("");
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [newLimit, setNewLimit] = useState("");
  const [roleAddress, setRoleAddress] = useState("");
  const [balance, setBalance] = useState("0");
  const [totalDeposits, setTotalDeposits] = useState("0");
  const [paused, setPaused] = useState(false);
  const [role, setRole] = useState("");
  const [loading, setLoading] = useState(true);
  const [targetBalanceAddress, setTargetBalanceAddress] = useState("");
  const [targetBalance, setTargetBalance] = useState("");
  const [roleToManage, setRoleToManage] = useState("INVESTOR_ROLE");
  const [darkMode, setDarkMode] = useState(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("darkMode") === "true";
    }
    return true;
  });

  // Role identifiers
  const INVESTOR_ROLE = ethers.id("INVESTOR_ROLE");
  const ADMIN_ROLE = ethers.id("ADMIN_ROLE");
  const AUDITOR_ROLE = ethers.id("AUDITOR_ROLE");

  // On mount: connect wallet, fetch state
  useEffect(() => {
    const init = async () => {
      try {
        if (typeof window.ethereum !== "undefined") {
          // Ensure network is correct
          const currentChainId = await window.ethereum.request({ method: "eth_chainId" });
          if (currentChainId !== DESIRED_CHAIN_ID) {
            try {
              await window.ethereum.request({
                method: "wallet_switchEthereumChain",
                params: [{ chainId: DESIRED_CHAIN_ID }],
              });
            } catch (switchError) {
              alert("Please switch to the correct network in MetaMask.");
              return;
            }
          }
          setLoading(true);
          const _provider = new ethers.providers.Web3Provider(window.ethereum);
          await _provider.send("eth_requestAccounts", []);
          const _signer = _provider.getSigner();
          const _account = await _signer.getAddress();
          const _contract = new Contract(VAULT_ADDRESS, vaultAbi, _signer);

          setProvider(_provider);
          setSigner(_signer);
          setAccount(_account);
          setContract(_contract);

          // Get balances and contract state
          const bal = await _contract.balances(_account);
          const total = await _contract.totalDeposits();
          const isPaused = await _contract.paused();

          setBalance(ethers.formatEther(bal));
          setTotalDeposits(ethers.formatEther(total));
          setPaused(isPaused);

          // Determine role
          const isInvestor = await _contract.hasRole(INVESTOR_ROLE, _account);
          const isAdmin = await _contract.hasRole(ADMIN_ROLE, _account);
          const isAuditor = await _contract.hasRole(AUDITOR_ROLE, _account);

          if (isAdmin) setRole("ADMIN");
          else if (isInvestor) setRole("INVESTOR");
          else if (isAuditor) setRole("AUDITOR");
          else setRole("NONE");

          setLoading(false);
        }
      } catch (err) {
        alert("Initialization failed: " + err.message);
        setLoading(false);
      }
    };
    init();
  }, []);

  // Role Management
  const grantRole = async () => {
    try {
      if (!ethers.isAddress(roleAddress)) return alert("Invalid address");
      const roleId =
        roleToManage === "INVESTOR_ROLE"
          ? INVESTOR_ROLE
          : AUDITOR_ROLE;
      const tx = await contract.grantVaultRole(roleId, roleAddress);
      await tx.wait();
      alert(`${roleToManage} granted to ${roleAddress}`);
    } catch (err) {
      alert("Grant role failed: " + err.message);
    }
  };

  const revokeRole = async () => {
    try {
      if (!ethers.isAddress(roleAddress)) return alert("Invalid address");
      const roleId =
        roleToManage === "INVESTOR_ROLE"
          ? INVESTOR_ROLE
          : AUDITOR_ROLE;
      const tx = await contract.revokeVaultRole(roleId, roleAddress);
      await tx.wait();
      alert(`${roleToManage} revoked from ${roleAddress}`);
    } catch (err) {
      alert("Revoke role failed: " + err.message);
    }
  };

  // Auditor view
  const fetchBalanceOf = async () => {
    try {
      if (!ethers.isAddress(targetBalanceAddress)) return alert("Invalid address");
      const bal = await contract.viewBalance(targetBalanceAddress);
      setTargetBalance(ethers.formatEther(bal));
    } catch (err) {
      alert("View balance failed: " + err.message);
    }
  };

  // User actions
  const deposit = async () => {
    try {
      const tx = await contract.deposit(ethers.parseEther(depositAmount));
      await tx.wait();
      alert("Deposit successful!");
      window.location.reload();
    } catch (err) {
      alert("Deposit failed: " + err.message);
    }
  };

  const withdraw = async () => {
    try {
      const tx = await contract.withdraw(ethers.parseEther(withdrawAmount));
      await tx.wait();
      alert("Withdrawal successful!");
      window.location.reload();
    } catch (err) {
      alert("Withdrawal failed: " + err.message);
    }
  };

  const emergencyWithdraw = async () => {
    try {
      const tx = await contract.emergencyWithdraw();
      await tx.wait();
      alert("Emergency withdrawal successful!");
      window.location.reload();
    } catch (err) {
      alert("Emergency withdrawal failed: " + err.message);
    }
  };

  const pauseContract = async () => {
    try {
      const tx = await contract.pause();
      await tx.wait();
      alert("Vault paused");
      window.location.reload();
    } catch (err) {
      alert("Pause failed: " + err.message);
    }
  };

  const unpauseContract = async () => {
    try {
      const tx = await contract.unpause();
      await tx.wait();
      alert("Vault unpaused");
      window.location.reload();
    } catch (err) {
      alert("Unpause failed: " + err.message);
    }
  };

  const updateLimit = async () => {
    try {
      const tx = await contract.setDepositLimit(ethers.parseEther(newLimit));
      await tx.wait();
      alert("Deposit limit updated!");
      window.location.reload();
    } catch (err) {
      alert("Failed to update deposit limit: " + err.message);
    }
  };

  // Loading UI
  if (loading) {
    return (
      <div className="p-6 text-center text-xl font-semibold">
        🚀 Connecting to SecureVault...
      </div>
    );
  }

  // UI rendering
  return (
    <div className={`${darkMode ? "dark" : ""}`}>
      <div className="flex flex-col items-center justify-center px-4 py-8 dark:bg-gray-900 dark:text-white">
        <div className="w-full max-w-4xl flex flex-col gap-8">

          <div className="flex justify-between items-center mb-6">
            <h1 className="text-3xl font-bold">🔒 SecureVault dApp</h1>
          </div>

          {/* Infos principales */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-6 transition">
            <p><strong>Wallet:</strong> {account}</p>
            <p><strong>Role:</strong> {role}</p>
            <p><strong>Status:</strong> {paused ? "⏸️ Paused" : "✅ Active"}</p>
            <p><strong>Your Balance:</strong> {balance} TST</p>
            <p><strong>Total Deposits:</strong> {totalDeposits} TST</p>
          </div>

          {/* Investor */}
          {role === "INVESTOR" && !paused && (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-6 space-y-4">
              <h2 className="text-xl font-semibold mb-2">💰 Investor Actions</h2>
              <div className="flex gap-2">
                <input className="flex-1 p-2 rounded border dark:bg-gray-700" placeholder="Deposit amount" value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} />
                <button onClick={deposit} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">Deposit</button>
              </div>
              <div className="flex gap-2">
                <input className="flex-1 p-2 rounded border dark:bg-gray-700" placeholder="Withdraw amount" value={withdrawAmount} onChange={(e) => setWithdrawAmount(e.target.value)} />
                <button onClick={withdraw} className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">Withdraw</button>
              </div>
            </div>
          )}

          {role === "INVESTOR" && paused && (
            <div className="bg-yellow-100 dark:bg-yellow-700 rounded-lg p-4 mb-6">
              <h2 className="text-lg font-semibold">⚠️ Emergency Withdraw</h2>
              <button onClick={emergencyWithdraw} className="w-full px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600 transition mt-2">Withdraw All</button>
            </div>
          )}

          {/* Auditor */}
          {role === "AUDITOR" && (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-6">
              <h2 className="text-xl font-semibold mb-2">🔍 Auditor Tools</h2>
              <div className="flex gap-2">
                <input className="flex-1 p-2 rounded border dark:bg-gray-700" placeholder="Address to audit" value={targetBalanceAddress} onChange={(e) => setTargetBalanceAddress(e.target.value)} />
                <button onClick={fetchBalanceOf} className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition">View Balance</button>
              </div>
              {targetBalance && <p className="mt-2">Balance of {targetBalanceAddress}: {targetBalance} TST</p>}
            </div>
          )}

          {/* Admin */}
          {role === "ADMIN" && (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4 space-y-4">
              <h2 className="text-xl font-semibold">🛠 Admin Panel</h2>
              <div className="flex gap-2">
                <button onClick={pauseContract} className="px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600 transition">Pause</button>
                <button onClick={unpauseContract} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition">Unpause</button>
              </div>
              <div className="flex gap-2">
                <input className="flex-1 p-2 rounded border dark:bg-gray-700" placeholder="New deposit limit (ETH)" value={newLimit} onChange={(e) => setNewLimit(e.target.value)} />
                <button onClick={updateLimit} className="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 transition">Update Limit</button>
              </div>
              <div className="flex gap-2">
                <select className="p-2 rounded border dark:bg-gray-700" value={roleToManage} onChange={(e) => setRoleToManage(e.target.value)}>
                  <option value="INVESTOR_ROLE">Investor</option>
                  <option value="AUDITOR_ROLE">Auditor</option>
                </select>
                <input className="flex-1 p-2 rounded border dark:bg-gray-700" placeholder="Address to manage" value={roleAddress} onChange={(e) => setRoleAddress(e.target.value)} />
                <button onClick={grantRole} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">Grant</button>
                <button onClick={revokeRole} className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">Revoke</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}