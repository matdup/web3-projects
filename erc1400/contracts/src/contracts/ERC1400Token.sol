// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/// @title ERC1400 Production Token with Compliance, Partitions, Document Management and Forced Transfers
/// @notice Fully compliant ERC-1400 token integrating ERC-1594 (compliance checks), ERC-1643 (document management), and ERC-1644 (forced transfers).
/// @dev Designed for regulated STO (Security Token Offering) scenarios. Includes KYC enforcement, partitions, document storage, and regulator powers.
/// @author mat
contract ERC1400Token is ERC20, AccessControl, ReentrancyGuard {
    // ------------------------------------------------------------------------
    // ROLES
    // ------------------------------------------------------------------------
    /// @notice Role identifier for compliance officers (manages KYC & partitions).
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    /// @notice Role identifier for regulators (can enforce forced transfers).
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");

    // ------------------------------------------------------------------------
    // KYC & PARTITIONS
    // ------------------------------------------------------------------------
    mapping(address => bool) public whitelist;
    mapping(address => bytes32) public partitions;

    /// @notice Default partition assigned upon KYC approval if none is specified.
    bytes32 public constant DEFAULT_PARTITION = keccak256("PUBLIC");

    // ------------------------------------------------------------------------
    // DOCUMENT MANAGEMENT (ERC-1643)
    // ------------------------------------------------------------------------
    struct Document {
        string uri;
        bytes32 hash;
        uint256 timestamp;
    }
    mapping(bytes32 => Document) private _documents;

    // ------------------------------------------------------------------------
    // EVENTS
    // ------------------------------------------------------------------------
    event AddressWhitelisted(address indexed account, bool status);
    event PartitionAssigned(address indexed account, bytes32 indexed partition);
    event DocumentAdded(bytes32 indexed docName, string uri, bytes32 hash, uint256 timestamp);
    event DocumentRemoved(bytes32 indexed docName);
    event ForcedTransfer(address indexed operator, address indexed from, address indexed to, uint256 amount, string reason);

    // ------------------------------------------------------------------------
    // CONSTRUCTOR
    // ------------------------------------------------------------------------
    /// @notice Deploys ERC1400 token with roles and default parameters.
    /// @dev Deployer is assigned DEFAULT_ADMIN_ROLE, COMPLIANCE_ROLE, and REGULATOR_ROLE.
    constructor() ERC20("Tokenized Asset", "TOK1400") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COMPLIANCE_ROLE, msg.sender);
        _grantRole(REGULATOR_ROLE, msg.sender);
    }

    // ------------------------------------------------------------------------
    // KYC / COMPLIANCE
    // ------------------------------------------------------------------------

    /// @notice Adds an address to the whitelist and assigns default partition if none exists.
    /// @dev Only callable by COMPLIANCE_ROLE.
    /// @param account Address to whitelist.
    function addToWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        whitelist[account] = true;
        if (partitions[account] == bytes32(0)) {
            partitions[account] = DEFAULT_PARTITION;
            emit PartitionAssigned(account, DEFAULT_PARTITION);
        }
        emit AddressWhitelisted(account, true);
    }

    /// @notice Removes an address from the whitelist (revokes KYC approval).
    /// @param account Address to remove.
    function removeFromWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        whitelist[account] = false;
        emit AddressWhitelisted(account, false);
    }

    /// @notice Checks if an address is KYC-approved.
    /// @param account Address to verify.
    /// @return bool True if address is KYC-approved.
    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }

    // ------------------------------------------------------------------------
    // PARTITION MANAGEMENT
    // ------------------------------------------------------------------------

    /// @notice Assigns a token partition to a whitelisted address.
    /// @dev Used to segregate regulated investors (e.g., "RESTRICTED") from public.
    /// @param account Address to assign partition.
    /// @param partition Partition label (keccak256 hash recommended).
    function assignPartition(address account, bytes32 partition) external onlyRole(COMPLIANCE_ROLE) {
        require(isWhitelisted(account), "KYC required");
        require(partition != bytes32(0), "Invalid partition");
        partitions[account] = partition;
        emit PartitionAssigned(account, partition);
    }

    /// @notice Returns the partition of a given address.
    /// @param account Address to query.
    /// @return bytes32 The assigned partition label.
    function getPartition(address account) public view returns (bytes32) {
        return partitions[account];
    }

    // ------------------------------------------------------------------------
    // DOCUMENT MANAGEMENT (ERC-1643)
    // ------------------------------------------------------------------------

    /// @notice Adds or updates an official document linked to this token.
    /// @dev Only callable by DEFAULT_ADMIN_ROLE. Documents include prospectuses or compliance references.
    /// @param docName Document identifier (e.g., keccak256("Prospectus")).
    /// @param uri URI pointing to the off-chain document.
    /// @param hash Keccak-256 hash of the document contents (integrity proof).
    function addDocument(bytes32 docName, string memory uri, bytes32 hash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(uri).length > 0, "Invalid URI");
        _documents[docName] = Document(uri, hash, block.timestamp);
        emit DocumentAdded(docName, uri, hash, block.timestamp);
    }

    /// @notice Removes an official document.
    /// @dev Only callable by DEFAULT_ADMIN_ROLE.
    /// @param docName Document identifier to remove.
    function removeDocument(bytes32 docName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(_documents[docName].uri).length > 0, "Document not found");
        delete _documents[docName];
        emit DocumentRemoved(docName);
    }

    /// @notice Retrieves document metadata.
    /// @param docName Document identifier.
    /// @return string Document URI.
    /// @return bytes32 Document hash.
    /// @return uint256 Timestamp of last update.
    function getDocument(bytes32 docName) external view returns (string memory, bytes32, uint256) {
        Document memory doc = _documents[docName];
        require(bytes(doc.uri).length > 0, "Document not found");
        return (doc.uri, doc.hash, doc.timestamp);
    }

    // ------------------------------------------------------------------------
    // ERC-1594 Compliance Hooks
    // ------------------------------------------------------------------------

    /// @notice Check if a transfer is valid before execution.
    /// @param from Sender address.
    /// @param to Recipient address.
    /// @param amount Token amount.
    /// @return bool True if transfer is compliant.
    function canTransfer(address from, address to, uint256 amount) public view returns (bool) {
        if (!isWhitelisted(from) || !isWhitelisted(to)) return false;
        if (partitions[from] != partitions[to]) return false;
        if (balanceOf(from) < amount) return false;
        return true;
    }

    /// @notice Check if a transfer by partition is valid before execution.
    /// @param partition Partition label.
    /// @param from Sender address.
    /// @param to Recipient address.
    /// @param amount Token amount.
    /// @return bool True if transfer is compliant.
    function canTransferByPartition(bytes32 partition, address from, address to, uint256 amount) public view returns (bool) {
        if (partitions[from] != partition || partitions[to] != partition) return false;
        return canTransfer(from, to, amount);
    }

    // ------------------------------------------------------------------------
    // TOKEN OPERATIONS (MINT / BURN)
    // ------------------------------------------------------------------------

    /// @notice Mints new tokens to a KYC-approved address.
    /// @dev Only DEFAULT_ADMIN_ROLE can mint.
    /// @param to Recipient (must be whitelisted).
    /// @param amount Amount to mint.
    function mint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(isWhitelisted(to), "Recipient not KYC-approved");
        _mint(to, amount);
    }

    /// @notice Burns tokens from the caller's balance.
    /// @param amount Amount to burn.
    function burn(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
    }

    // ------------------------------------------------------------------------
    // TRANSFERS WITH COMPLIANCE
    // ------------------------------------------------------------------------

    /// @notice Overrides ERC20 transfer with compliance and partition checks.
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "Invalid recipient");
        _validateCompliance(msg.sender, to);
        return super.transfer(to, amount);
    }

    /// @notice Overrides ERC20 transferFrom with compliance and partition checks.
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "Invalid recipient");
        _validateCompliance(from, to);
        return super.transferFrom(from, to, amount);
    }

    /// @notice Internal compliance validation enforcing KYC and partition match.
    function _validateCompliance(address from, address to) internal view {
        require(isWhitelisted(from), "Sender not KYC-approved");
        require(isWhitelisted(to), "Recipient not KYC-approved");
        require(partitions[to] == partitions[from], "Partition mismatch");
    }

    // ------------------------------------------------------------------------
    // REGULATORY FORCED TRANSFERS (ERC-1644)
    // ------------------------------------------------------------------------

    /// @notice Executes a forced transfer by a regulator.
    /// @dev Bypasses allowances and compliance; used in court-ordered or regulatory enforcement cases.
    /// @param from Source address (tokens are seized from here).
    /// @param to Destination address.
    /// @param amount Number of tokens to transfer.
    /// @param reason Justification string.
    function forceTransfer(address from, address to, uint256 amount, string calldata reason)
        external
        onlyRole(REGULATOR_ROLE)
        nonReentrant
    {
        require(from != address(0) && to != address(0), "Invalid address");
        _transfer(from, to, amount);
        emit ForcedTransfer(msg.sender, from, to, amount, reason);
    }
}