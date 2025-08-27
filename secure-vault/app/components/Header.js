"use client";
import { useState, useEffect } from "react";
import { MoonIcon, SunIcon } from "@heroicons/react/24/outline";

export default function Header() {
  const [darkMode, setDarkMode] = useState(false);
  const [wallet, setWallet] = useState(null);

  useEffect(() => {
    const savedDark = localStorage.getItem("darkMode") === "true";
    setDarkMode(savedDark);
    if (savedDark) {
        document.documentElement.classList.add("dark");
    } else {
        document.documentElement.classList.remove("dark");
    }

    if (window.ethereum?.selectedAddress) {
      setWallet(window.ethereum.selectedAddress);
    }
  }, []);

  const toggleDarkMode = () => {
    const newMode = !darkMode;
    setDarkMode(newMode);
    localStorage.setItem("darkMode", newMode);
    if (newMode) {
        document.documentElement.classList.add("dark");
    } else {
        document.documentElement.classList.remove("dark");
    }
    };

  const connectWallet = async () => {
    if (window.ethereum) {
      const [account] = await window.ethereum.request({ method: "eth_requestAccounts" });
      setWallet(account);
    } else {
      alert("MetaMask not found. Please install it.");
    }
  };

  return (
    <div className="sticky top-0 z-50 backdrop-blur-md bg-white/80 dark:bg-gray-800/70 border-b border-gray-200 dark:border-gray-700 shadow-sm">
      <div className="max-w-6xl mx-auto flex justify-between items-center px-6 py-4">
        <h1 className="text-2xl font-extrabold tracking-tight text-blue-600 dark:text-blue-400">
          🔒 SecureVault
        </h1>
        <div className="flex items-center gap-4">
          {wallet ? (
            <span className="text-sm font-mono bg-gray-200 dark:bg-gray-700 px-4 py-2 rounded-xl shadow-inner border border-gray-300 dark:border-gray-600">
              {wallet.slice(0, 6)}...{wallet.slice(-4)}
            </span>
          ) : (
            <button
              onClick={connectWallet}
              className="bg-gradient-to-r from-blue-500 to-indigo-600 hover:scale-105 px-4 py-2 rounded-xl text-white shadow-lg transition-all duration-200"
            >
              Connect Wallet
            </button>
          )}
          <button
            onClick={toggleDarkMode}
            className="p-2 rounded-xl bg-gray-200 dark:bg-gray-700 hover:scale-110 transition"
          >
            {darkMode ? (
              <SunIcon className="w-5 h-5 text-yellow-400" />
            ) : (
              <MoonIcon className="w-5 h-5 text-gray-700" />
            )}
          </button>
        </div>
      </div>
    </div>
  );
}