// app/layout.js
"use client";

import { useState, useEffect } from "react";
import "./globals.css";

export default function RootLayout({ children }) {
  const [darkMode, setDarkMode] = useState(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("darkMode") === "true";
    }
    return false;
  });

  useEffect(() => {
    if (typeof window !== "undefined") {
      localStorage.setItem("darkMode", darkMode);
      document.documentElement.classList.toggle("dark", darkMode);
    }
  }, [darkMode]);

  return (
    <html lang="en" className={darkMode ? "dark" : ""}>
      <body className="bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-white">
        {/* Sidebar */}
        <aside className="fixed top-0 left-0 z-50 w-64 h-screen bg-white dark:bg-gray-800 shadow-xl border-r border-gray-200 dark:border-gray-700 p-6">
          <h2 className="text-2xl font-bold mb-10 text-center tracking-tight">🔒 SecureVault</h2>

          {/* Wallet Info */}
          <div className="bg-gray-100 dark:bg-gray-700 rounded p-3 text-sm text-center mb-8 shadow-inner">
            {typeof window !== "undefined" && window.ethereum?.selectedAddress 
              ? <p>Wallet: {window.ethereum.selectedAddress.slice(0, 6)}...{window.ethereum.selectedAddress.slice(-4)}</p>
              : <button className="bg-blue-600 text-white w-full py-2 rounded-lg hover:bg-blue-700 transition">Connect Wallet</button>}
          </div>

          {/* Navigation */}
          <nav className="flex flex-col gap-3 text-gray-700 dark:text-gray-300">
            <a href="#" className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-blue-100 dark:hover:bg-gray-700 transition">🏦 <span>Dashboard</span></a>
            <a href="#investor" className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-blue-100 dark:hover:bg-gray-700 transition">💰 <span>Investor</span></a>
            <a href="#auditor" className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-blue-100 dark:hover:bg-gray-700 transition">🔎 <span>Auditor</span></a>
            <a href="#admin" className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-blue-100 dark:hover:bg-gray-700 transition">⚙️ <span>Admin</span></a>
          </nav>

          <div className="flex-1"></div>

          {/* Dark Mode */}
          <button
            onClick={() => setDarkMode(!darkMode)}
            className="mt-6 py-2 bg-gray-200 dark:bg-gray-700 rounded-lg hover:scale-105 transition"
          >
            {darkMode ? "☀️ Light Mode" : "🌙 Dark Mode"}
          </button>
        </aside>

        {/* Main Content */}
        <main className="ml-64 w-full bg-gray-50 dark:bg-gray-900 min-h-screen flex justify-center items-start">
          <div className="w-full max-w-5xl px-6">
            {children}
          </div>
        </main>
      </body>
    </html>
  );
}