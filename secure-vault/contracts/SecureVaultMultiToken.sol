// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Interface for an external price oracle returning token prices in USD (1e18)
interface IPriceOracle {
    function getUSDPrice(address token) external view returns (uint256);
}

/// @title SecureVaultMultiToken - A secure, role-based multi-token vault with deposit limits and emergency withdrawal
/// @author Mat
/// @notice This contract allows investors to deposit and withdraw multiple ERC-20 tokens with admin control
/// @dev Uses OpenZeppelin's AccessControl, Pausable, and ReentrancyGuard for robust permissions and security
contract SecureVaultMultiToken is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // role constant can be calculated off-chain for micro-gain gas
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE"); // role constant can be calculated off-chain for micro-gain gas
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE"); // role constant can be calculated off-chain for micro-gain gas

    /// @notice Total deposits per token
    mapping(address => uint256) public totalDeposits;

    /// @notice Deposit limit per address per token
    mapping(address => uint256) public depositLimitPerToken;

    /// @notice Balances mapping: token => user => balance
    mapping(address => mapping(address => uint256)) public balances;

    /// @notice Mapping to track whitelisted tokens
    mapping(address => bool) public isTokenWhitelisted;

    /// @notice Mapping to track if a token is registered already
    mapping(address => bool) public isTokenRegistered;

    /// @notice List of tokens tracked for TVL calculation
    /// @dev Be cautious: If many tokens are registered, iterating over this array in 
    ///      totalValueLocked() could become costly in gas for on-chain calls. 
    ///      For large-scale production, consider off-chain aggregation or incremental updates.
    address[] public registeredTokens;

    /// @notice Oracle contract for TVL calculation
    IPriceOracle public oracle;

    /// @notice Event for when a deposit is made
    /// @param token The token address deposited
    /// @param user The address of the user making the deposit
    /// @param amount The amount of tokens deposited
    /// @param total The total deposits for this token after the deposit
    event Deposited(address indexed token, address indexed user, uint256 amount, uint256 total);

    /// @notice Event for when a withdrawal is made
    /// @param token The token address withdrawn
    /// @param user The address of the user making the withdrawal
    /// @param amount The amount of tokens withdrawn
    /// @param total The total deposits for this token after the withdrawal
    event Withdrawn(address indexed token, address indexed user, uint256 amount, uint256 total);

    /// @notice Event for when an emergency withdrawal is made
    /// @param token The token address withdrawn
    /// @param user The address of the user making the emergency withdrawal
    /// @param amount The amount of tokens withdrawn in an emergency
    /// @param total The total deposits for this token after the emergency withdrawal
    event EmergencyWithdrawal(address indexed token, address indexed user, uint256 amount, uint256 total);

    /// @notice Event for when the deposit limit for a token is updated
    /// @param token The token address updated
    /// @param newLimit The new deposit limit for that token
    event DepositLimitUpdated(address indexed token, uint256 newLimit);

    /// @notice Emitted when a token's whitelist status is updated
    /// @param token The address of the token
    /// @param status True if whitelisted, false if removed
    event TokenWhitelisted(address indexed token, bool status);

    /// @notice Emitted when the oracle is updated
    /// @param newOracle The address of the new oracle
    event OracleUpdated(address indexed newOracle);

    /// @notice Initializes the vault and grants admin role to deployer
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Deposit tokens into the vault
    /// @param token The ERC-20 token to deposit
    /// @param amount The amount of tokens to deposit
    function deposit(address token, uint256 amount) external whenNotPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        require(isTokenWhitelisted[token], "Token not allowed");
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[token][msg.sender] + amount <= depositLimitPerToken[token], "Deposit limit exceeded");

        balances[token][msg.sender] += amount;
        totalDeposits[token] += amount;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(token, msg.sender, amount, totalDeposits[token]);
    }

    /// @notice Withdraw tokens from the vault
    /// @param token The ERC-20 token to withdraw
    /// @param amount The amount of tokens to withdraw
    function withdraw(address token, uint256 amount) external whenNotPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[token][msg.sender] >= amount, "Insufficient balance");

        balances[token][msg.sender] -= amount;
        totalDeposits[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(token, msg.sender, amount, totalDeposits[token]);
    }

    /// @notice Emergency withdraw only works when paused
    /// @param token The ERC-20 token to withdraw
    function emergencyWithdraw(address token) external whenPaused nonReentrant onlyRole(INVESTOR_ROLE) {
        uint256 amount = balances[token][msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[token][msg.sender] = 0;
        totalDeposits[token] -= amount;

        IERC20(token).safeTransfer(msg.sender, amount);
        emit EmergencyWithdrawal(token, msg.sender, amount, totalDeposits[token]);
    }

    /// @notice Pauses deposit and withdrawal operations
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses deposit and withdrawal operations
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Updates the deposit limit for a specific token
    /// @param token The token address
    /// @param newLimit The new deposit limit
    function setDepositLimit(address token, uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Invalid token address");
        depositLimitPerToken[token] = newLimit;
        emit DepositLimitUpdated(token, newLimit);
    }

    /// @notice Updates deposit limits for multiple tokens in a single transaction (batch admin UX)
    /// @param tokens An array of token addresses
    /// @param limits An array of deposit limits corresponding to each token
    function setDepositLimits(address[] calldata tokens, uint256[] calldata limits) external onlyRole(ADMIN_ROLE) {
        require(tokens.length == limits.length, "Length mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token address");
            depositLimitPerToken[tokens[i]] = limits[i];
            emit DepositLimitUpdated(tokens[i], limits[i]);
        }
    }

    /// @notice Adds or removes a token from the whitelist
    /// @param token The token address to whitelist or remove
    /// @param status True to whitelist, false to remove
    function setTokenWhitelist(address token, bool status) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Invalid token address");
        isTokenWhitelisted[token] = status;
        emit TokenWhitelisted(token, status);
    }

    /// @notice Registers a token for TVL tracking
    /// @param token The token address to register
    function registerToken(address token) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Invalid token");
        require(!isTokenRegistered[token], "Already registered");
        isTokenRegistered[token] = true;
        registeredTokens.push(token);
    }

    /// @notice Sets the price oracle contract address
    /// @param _oracle The address of the new oracle contract
    function setOracle(address _oracle) external onlyRole(ADMIN_ROLE) {
        require(_oracle != address(0), "Invalid oracle");
        oracle = IPriceOracle(_oracle);
        emit OracleUpdated(_oracle);
    }

    /// @notice Calculates the total value locked (TVL) across all registered tokens in USD
    /// @dev Requires an oracle returning USD prices with 18 decimals
    /// @dev Note: In a production environment, if many tokens are registered, this loop 
    ///      could become expensive in gas (even if this is a view function).
    ///      For a more scalable approach, off-chain indexing or incremental updates should be considered.
    /// @return totalUSD The total value locked in USD (1e18 precision)
    function totalValueLocked() external view returns (uint256 totalUSD) {
        require(address(oracle) != address(0), "Oracle not set");
        for (uint256 i = 0; i < registeredTokens.length; i++) {
            address token = registeredTokens[i];
            if (isTokenWhitelisted[token] && totalDeposits[token] > 0) {
                uint256 price = oracle.getUSDPrice(token);
                totalUSD += (totalDeposits[token] * price) / 1e18;
            }
        }
    }

    /// @notice Grants a role to an account (admin only)
    function grantVaultRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from an account (admin only)
    function revokeVaultRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /// @notice Allows auditors to view the balance of a user for a specific token
    function viewBalance(address token, address account) external view onlyRole(AUDITOR_ROLE) returns (uint256) {
        return balances[token][account];
    }

    /// @notice Returns the caller's balance for a given token (investor-only)
    function getMyBalance(address token) external view onlyRole(INVESTOR_ROLE) returns (uint256) {
        return balances[token][msg.sender];
    }

    /// @notice Allows admin to recover any ERC-20 tokens mistakenly sent to the vault
    function recoverERC20(address tokenAddress, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(depositLimitPerToken[tokenAddress] == 0, "Cannot recover active vault token");
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}