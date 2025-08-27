// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SecureVault - A secure, role-based token vault with deposit limits and emergency withdrawal
/// @author Mat
/// @notice This contract allows investors to deposit and withdraw ERC-20 tokens with admin control
/// @dev Uses OpenZeppelin's AccessControl, Pausable, and ReentrancyGuard for robust permissions and security
contract SecureVault is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // role constant can be calculated off-chain for micro-gain gas
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE"); // role constant can be calculated off-chain for micro-gain gas
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE"); // role constant can be calculated off-chain for micro-gain gas

    IERC20 public immutable token;
    uint256 public totalDeposits;
    uint256 public depositLimitPerAddress;

    mapping(address => uint256) public balances;

    /// @notice Event for when a deposit is made
    /// @param user The address of the user making the deposit
    /// @param amount The amount of tokens deposited
    /// @param total The total deposits after the deposit is made
    event Deposited(address indexed user, uint256 amount, uint256 total);
    
    /// @notice Event for when a withdrawal is made
    /// @param user The address of the user making the withdrawal
    /// @param amount The amount of tokens withdrawn
    /// @param total The total deposits after the withdrawal is made
    event Withdrawn(address indexed user, uint256 amount, uint256 total);
    
    /// @notice Event for when an emergency withdrawal is made
    /// @param user The address of the user making the emergency withdrawal
    /// @param amount The amount of tokens withdrawn in an emergency
    /// @param total The total deposits after the emergency withdrawal is made
    event EmergencyWithdrawal(address indexed user, uint256 amount, uint256 total);
    
    /// @notice Event for when the deposit limit is updated
    /// @param newLimit The new deposit limit
    event DepositLimitUpdated(uint256 newLimit);

    /// @notice Initializes the vault with the token address and deposit limit
    /// @param _token The address of the ERC-20 token to be accepted
    /// @param _depositLimit The maximum deposit per address
    constructor(address _token, uint256 _depositLimit) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
        depositLimitPerAddress = _depositLimit;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Deposit tokens into the vault
    /// @param amount The amount of tokens to deposit
    function deposit(uint256 amount) external whenNotPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] + amount <= depositLimitPerAddress, "Deposit limit exceeded");

        balances[msg.sender] += amount;
        totalDeposits += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount, totalDeposits);
    }

    /// @notice Withdraw tokens from the vault
    /// @param amount The amount of tokens to withdraw
    function withdraw(uint256 amount) external whenNotPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalDeposits -= amount;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, totalDeposits);
    }

    /// @notice Emergency withdraw only works when paused and investor has funds
    function emergencyWithdraw() external whenPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        totalDeposits -= amount;

        token.safeTransfer(msg.sender, amount);
        emit EmergencyWithdrawal(msg.sender, amount, totalDeposits);
    }

    /// @notice Pauses deposit and withdrawal operations
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses deposit and withdrawal operations
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Updates the deposit limit per user
    /// @param newLimit New deposit limit in token units
    function setDepositLimit(uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        depositLimitPerAddress = newLimit;
        emit DepositLimitUpdated(newLimit);
    }

    /// @notice Grants a role to an account (admin only)
    /// @param role The role to grant (INVESTOR_ROLE, AUDITOR_ROLE, etc.)
    /// @param account The address to assign the role to
    function grantVaultRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from an account (admin only)
    /// @param role The role to revoke
    /// @param account The address to remove the role from
    function revokeVaultRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /// @notice Allows auditors to view the balance of an address
    /// @param account The address to check the balance of
    /// @return The balance of the specified address
    function viewBalance(address account) external view onlyRole(AUDITOR_ROLE) returns (uint256) {
        return balances[account];
    }

    /// @notice Returns the balance of the caller (investor-only)
    /// @return The caller's current vault balance
    function getMyBalance() external view onlyRole(INVESTOR_ROLE) returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice Allows admin to recover any ERC-20 tokens mistakenly sent to the vault (excluding the vault token)
    /// @param tokenAddress The address of the token to be recovered
    /// @param amount The amount of tokens to recover
    function recoverERC20(address tokenAddress, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(tokenAddress != address(token), "Cannot recover vault token");
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
