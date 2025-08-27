

ERC1400Token – Production-Grade Security Token Standard Implementation

Fully compliant ERC-1400 token integrating:
	•	ERC-1594 – Pre-transfer compliance checks
	•	ERC-1643 – On-chain document management
	•	ERC-1644 – Regulator-enforced forced transfers

Designed for regulated Security Token Offerings (STOs), with built-in KYC enforcement, partition-based investor segregation, document storage, and regulatory intervention capabilities.

⸻

Features

1. Compliance Enforcement (ERC-1594)
	•	Whitelist-based KYC checks for both senders and receivers.
	•	Partition control to segregate investor groups (e.g., PUBLIC, RESTRICTED).
	•	canTransfer and canTransferByPartition for pre-validation without executing transfers.

2. Partition Management
	•	Default partition assigned upon KYC approval.
	•	Admin-controlled partition reassignment.

3. Document Management (ERC-1643)
	•	Add, update, and remove official documents (prospectus, legal terms, etc.).
	•	On-chain hash & timestamp for integrity verification.
	•	Indexed by a bytes32 document name identifier.

4. Regulatory Control (ERC-1644)
	•	forceTransfer function bypasses compliance checks for court orders or regulatory actions.
	•	Fully logged with ForcedTransfer event for auditability.

5. Secure ERC-20 Operations
	•	Minting restricted to admin and KYC-approved recipients.
	•	Burning available to token holders.
	•	Transfers automatically enforce compliance & partition matching.

⸻

Roles & Permissions

Role	Description
DEFAULT_ADMIN_ROLE	Full administrative privileges.
COMPLIANCE_ROLE	Manage KYC whitelist and partitions.
REGULATOR_ROLE	Execute forced transfers bypassing compliance checks.


⸻

Events
	•	AddressWhitelisted(address account, bool status)
	•	PartitionAssigned(address account, bytes32 partition)
	•	DocumentAdded(bytes32 docName, string uri, bytes32 hash, uint256 timestamp)
	•	DocumentRemoved(bytes32 docName)
	•	ForcedTransfer(address operator, address from, address to, uint256 amount, string reason)

⸻

Installation

forge install openzeppelin/openzeppelin-contracts


⸻

Deployment

Example using Foundry:

ERC1400Token token = new ERC1400Token();

By default:
	•	Deployer receives DEFAULT_ADMIN_ROLE, COMPLIANCE_ROLE, and REGULATOR_ROLE.

⸻

Usage Examples

Add to Whitelist & Assign Partition

token.addToWhitelist(userAddress);
token.assignPartition(userAddress, keccak256("RESTRICTED"));

Add a Document

token.addDocument(
    keccak256("Prospectus"),
    "https://example.com/prospectus.pdf",
    documentHash
);

Regulator Forced Transfer

token.forceTransfer(from, to, amount, "Court order");


⸻

Security Considerations
	•	Reentrancy protection applied to minting, burning, and forced transfers.
	•	Role-based access control prevents unauthorized actions.
	•	All compliance checks happen before transfers are executed.
	•	Events ensure full on-chain auditability.

⸻

Standards Compliance

Standard	Purpose
ERC-1400	Security token standard
ERC-1594	Transfer restrictions
ERC-1643	Document management
ERC-1644	Forced transfers
ERC-20	Basic token operations


⸻

License

MIT

⸻
