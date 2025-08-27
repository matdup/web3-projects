# 🔐 SecureVault Protocol

SecureVault is a secure, modular, and role-based ERC-20 token vault allowing controlled deposits, withdrawals, and emergency fund retrieval. Built with a strong focus on security, access control, and maintainability.

---

## 🧱 Stack

- **Smart Contracts**: Solidity (ERC-20, ERC-1400 compatible structure)
- **Architecture**: Modular smart contract design, role-based access control
- **Security**: ReentrancyGuard, Pausable, AccessControl, Custom Limits
- **Framework**: [Foundry](https://book.getfoundry.sh/) for testing and local dev
- **Frontend**: Next.js + Ethers.js + TailwindCSS

---

## 🚀 Features

### ✅ Smart Contract
- ERC-20 token vault with role-based permissions
- Investor deposits with individual limits
- Admin-controlled pause/unpause functions
- Emergency withdrawals when paused
- Dynamic deposit limit updates
- Role management (grant/revoke)

### ✅ Frontend
- Wallet connection (MetaMask)
- Investor actions: deposit, withdraw, emergency withdraw
- Admin dashboard: pause/unpause, set deposit limit, assign/revoke investor roles
- Real-time contract state (paused, balance, role)

### ✅ Tests
- **Framework**: Foundry
- **Coverage**:
  - Deposit/Withdraw happy path
  - Exceeding limits
  - Role validation and security
  - Emergency flow and pause logic

---

## 📂 Project Structure

```bash
securevault/
├── contracts/
│   └── SecureVault.sol
├── test/foundry/
│   └── SecureVault.t.sol
├── frontend/
│   └── app/index.js
├── abi/
│   └── SecureVault.json
├── scripts/
│   └── deploy.js
├── foundry.toml
├── hardhat.config.js
└── README.md
```

---

## ⚙️ Getting Started

### 🧪 Run Foundry tests
```bash
forge install
forge build
forge test
```

### 🧾 Compile Smart Contract (if using Hardhat)
```bash
npx hardhat compile
```

### 🔧 Run Frontend locally
```bash
cd frontend
npm install
npm run dev
```

---

## 🛡️ Security Considerations
- All critical functions are protected by roles (ADMIN, INVESTOR)
- Deposits have per-address limits
- Emergency withdrawal when contract is paused
- Gas-optimized with Solidity >=0.8.18

---

## 👨‍💻 Author

**Matdup**  
Blockchain Tech Lead — Full-Stack Web3 Developer  

---

## 📄 License

MIT © 2024 SecureVault Protocol

