//app/page.js

"use client";
import { useEffect, useState } from "react";
import { getContract, getSigner } from "../lib/ethers";
import { INVESTOR_ROLE, ADMIN_ROLE, AUDITOR_ROLE } from "../lib/roles";

export default function Home() {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const init = async () => {
      if (!window.ethereum) return alert("Install MetaMask");
      await window.ethereum.request({ method: "eth_requestAccounts" });

      const signer = await getSigner();
      const account = await signer.getAddress();
      const contract = await getContract();

      if (await contract.hasRole(ADMIN_ROLE, account)) window.location.href = "/admin";
      else if (await contract.hasRole(INVESTOR_ROLE, account)) window.location.href = "/investor";
      else if (await contract.hasRole(AUDITOR_ROLE, account)) window.location.href = "/auditor";
      else alert("You don't have any role assigned.");
      
      setLoading(false);
    };
    init();
  }, []);

  return (
    <div className="flex items-center justify-center min-h-screen text-xl">
      {loading ? "🔗 Connecting wallet and checking role..." : ""}
    </div>
  );
}
