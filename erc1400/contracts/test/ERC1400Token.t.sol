// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/contracts/ERC1400Token.sol";

contract ERC1400TokenTest is Test {
    ERC1400Token token;

    address admin      = makeAddr("admin");
    address compliance = makeAddr("compliance");
    address regulator  = makeAddr("regulator");
    address user1      = makeAddr("user1");
    address user2      = makeAddr("user2");
    address user3      = makeAddr("user3");

    bytes32 public constant RESTRICTED = keccak256("RESTRICTED");

    function setUp() public {
        vm.startPrank(admin);
        token = new ERC1400Token();
        token.grantRole(token.COMPLIANCE_ROLE(), compliance);
        token.grantRole(token.REGULATOR_ROLE(), regulator);
        vm.stopPrank();
    }

    // ---------------------------------------------------------------
    // UNIT TESTS
    // ---------------------------------------------------------------

    function testAddToWhitelistAndDefaultPartition() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        assertTrue(token.isWhitelisted(user1));
        assertEq(token.getPartition(user1), token.DEFAULT_PARTITION());
    }

    function testAssignPartition() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.assignPartition(user1, RESTRICTED);
        vm.stopPrank();

        assertEq(token.getPartition(user1), RESTRICTED);
    }

    function testMintAndTransferWithinPartition() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.prank(user1);
        token.transfer(user2, 500 ether);
        assertEq(token.balanceOf(user2), 500 ether);
    }

    function test_RevertWhen_TransferDifferentPartitions() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        token.assignPartition(user2, RESTRICTED); // different partition
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Partition mismatch");
        token.transfer(user2, 100 ether);
        vm.stopPrank();
    }

    function testForceTransferByRegulator() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.startPrank(regulator);
        token.forceTransfer(user1, user2, 200 ether, "Court Order");
        vm.stopPrank();

        assertEq(token.balanceOf(user2), 200 ether);
    }

    function testAddAndRemoveDocument() public {
        bytes32 docName = keccak256("Prospectus");
        string memory uri = "https://example.com/doc.pdf";
        bytes32 docHash = keccak256(abi.encodePacked("document content"));

        vm.startPrank(admin);
        token.addDocument(docName, uri, docHash);

        (string memory returnedUri, bytes32 returnedHash, uint256 timestamp) = token.getDocument(docName);
        assertEq(returnedUri, uri);
        assertEq(returnedHash, docHash);
        assertTrue(timestamp > 0);

        token.removeDocument(docName);

        // ✅ Either expect revert (if that's the intended design):
        vm.expectRevert("Document not found");
        token.getDocument(docName);

        // ❌ OR, if it should return empty values (no revert), remove the `expectRevert`:
        // (string memory emptyUri, bytes32 emptyHash, uint256 emptyTimestamp) = token.getDocument(docName);
        // assertEq(emptyUri, "");
        // assertEq(emptyHash, 0);
        // assertEq(emptyTimestamp, 0);
    }

    function test_RevertWhen_AddToWhitelistWithZeroAddress() public {
        vm.startPrank(compliance);
        vm.expectRevert("Invalid address");
        token.addToWhitelist(address(0));
        vm.stopPrank();
    }

    function test_RevertWhen_RemoveFromWhitelistWithZeroAddress() public {
        vm.startPrank(compliance);
        vm.expectRevert("Invalid address");
        token.removeFromWhitelist(address(0));
        vm.stopPrank();
    }

    function test_RemoveFromWhitelist() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        assertTrue(token.isWhitelisted(user1));

        token.removeFromWhitelist(user1);
        assertFalse(token.isWhitelisted(user1));
        vm.stopPrank();
    }

    function test_RevertWhen_AssignPartitionWithoutKYC() public {
        vm.startPrank(compliance);
        vm.expectRevert("KYC required");
        token.assignPartition(user1, RESTRICTED);
        vm.stopPrank();
    }

    function test_RevertWhen_AssignPartitionWithZeroPartition() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.expectRevert("Invalid partition");
        token.assignPartition(user1, bytes32(0));
        vm.stopPrank();
    }

    function test_RevertWhen_AddDocumentWithEmptyURI() public {
        bytes32 docName = keccak256("EmptyDoc");
        vm.startPrank(admin);
        vm.expectRevert("Invalid URI");
        token.addDocument(docName, "", keccak256("doc"));
        vm.stopPrank();
    }

    function test_RevertWhen_RemoveNonExistentDocument() public {
        vm.startPrank(admin);
        bytes32 fakeDoc = keccak256("FakeDoc");
        vm.expectRevert("Document not found");
        token.removeDocument(fakeDoc);
        vm.stopPrank();
    }

    function test_CanTransferChecks() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        assertTrue(token.canTransfer(user1, user2, 50 ether));
        assertFalse(token.canTransfer(user1, address(7), 10 ether)); // Non-KYC recipient
        assertFalse(token.canTransfer(user1, user2, 200 ether));     // Montant supérieur au solde
    }

    function test_CanTransferByPartitionChecks() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        token.assignPartition(user1, RESTRICTED);
        token.assignPartition(user2, RESTRICTED);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        assertTrue(token.canTransferByPartition(RESTRICTED, user1, user2, 50 ether));

        // Partition mismatch
        vm.startPrank(compliance);
        token.assignPartition(user2, token.DEFAULT_PARTITION());
        vm.stopPrank();
        assertFalse(token.canTransferByPartition(RESTRICTED, user1, user2, 50 ether));
    }

    function test_RevertWhen_MintToNonWhitelisted() public {
        vm.startPrank(admin);
        vm.expectRevert("Recipient not KYC-approved");
        token.mint(user1, 100 ether);
        vm.stopPrank();
    }

    function test_BurnTokens() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 500 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        token.burn(200 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 300 ether);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Invalid recipient");
        token.transfer(address(0), 10 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedForceTransfer() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        vm.startPrank(user2); // Pas régulateur
        vm.expectRevert(); // Revert dû à AccessControl
        token.forceTransfer(user1, user2, 10 ether, "Not allowed");
        vm.stopPrank();
    }

    function test_RevertWhen_ForceTransferInvalidAddress() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        vm.startPrank(regulator);
        vm.expectRevert("Invalid address");
        token.forceTransfer(user1, address(0), 10 ether, "Invalid");
        vm.stopPrank();
    }

    // ---------------------------------------------------------------
    // FUZZ TESTS (random inputs)
    // ---------------------------------------------------------------

    function testFuzzMintTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1_000_000 ether);

        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, amount);
        vm.stopPrank();

        vm.prank(user1);
        token.transfer(user2, amount);
        assertEq(token.balanceOf(user2), amount);
    }

    function testFuzzPartitionIsolation(bytes32 partition1, bytes32 partition2) public {
        vm.assume(partition1 != bytes32(0));
        vm.assume(partition2 != bytes32(0));
        vm.assume(partition1 != partition2);

        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        token.assignPartition(user1, partition1);
        token.assignPartition(user2, partition2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        vm.expectRevert("Partition mismatch");
        vm.prank(user1);
        token.transfer(user2, 50 ether);
    }

    function test_ApproveAndTransferFrom_Compliant() public {
        // KYC + même partition par défaut
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 100 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(user3, 60 ether);
        vm.stopPrank();

        vm.prank(user3);
        token.transferFrom(user1, user2, 60 ether);

        assertEq(token.balanceOf(user1), 40 ether);
        assertEq(token.balanceOf(user2), 60 ether);
    }

    function test_Revert_TransferFrom_NonKYCRecipient() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 50 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(user3, 50 ether);
        vm.stopPrank();

        vm.startPrank(user3);
        vm.expectRevert("Recipient not KYC-approved");
        token.transferFrom(user1, user2, 10 ether);
        vm.stopPrank();
    }

    function test_Revert_TransferFrom_PartitionMismatch() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        token.assignPartition(user2, RESTRICTED);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 50 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(user3, 50 ether);
        vm.stopPrank();

        vm.startPrank(user3);
        vm.expectRevert("Partition mismatch");
        token.transferFrom(user1, user2, 10 ether);
        vm.stopPrank();
    }

    function test_Revert_TransferFrom_AllowanceExceeded() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 10 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(user3, 5 ether);
        vm.stopPrank();

        vm.startPrank(user3);
        vm.expectRevert(); // ERC20: insufficient allowance
        token.transferFrom(user1, user2, 6 ether);
        vm.stopPrank();
    }

    function test_Events_WhitelistAndPartition() public {
        vm.startPrank(compliance);
        vm.expectEmit(true, false, false, true);
        emit ERC1400Token.AddressWhitelisted(user1, true);
        token.addToWhitelist(user1);

        vm.expectEmit(true, true, false, true);
        emit ERC1400Token.PartitionAssigned(user1, RESTRICTED);
        token.assignPartition(user1, RESTRICTED);
        vm.stopPrank();
    }

    function test_Events_DocAddRemove() public {
        bytes32 name = keccak256("KID");
        string memory uri = "ipfs://hash";
        bytes32 h = keccak256("doc");

        vm.startPrank(admin);

        // Seul docName est indexed → on ne checke pas les data
        vm.expectEmit(true, false, false, false);
        emit ERC1400Token.DocumentAdded(name, "", bytes32(0), 0);
        token.addDocument(name, uri, h);

        vm.expectEmit(true, false, false, false);
        emit ERC1400Token.DocumentRemoved(name);
        token.removeDocument(name);

        vm.stopPrank();
    }

    function test_Event_ForcedTransfer() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        vm.stopPrank();

        vm.startPrank(admin);
        token.mint(user1, 30 ether);
        vm.stopPrank();

        vm.startPrank(regulator);
        vm.expectEmit(true, true, true, true);
        emit ERC1400Token.ForcedTransfer(regulator, user1, user2, 10 ether, "Enforcement");
        token.forceTransfer(user1, user2, 10 ether, "Enforcement");
        vm.stopPrank();
    }

    function test_ForceTransfer_IgnoresKYCAndPartition() public {
        // user1 KYC yes, user2 not KYC
        vm.prank(compliance);
        token.addToWhitelist(user1);

        vm.prank(admin);
        token.mint(user1, 40 ether);

        // user2 reste non-KYC + partition non définie
        vm.prank(regulator);
        token.forceTransfer(user1, user2, 15 ether, "Bypass");

        assertEq(token.balanceOf(user2), 15 ether); // réussite malgré non-KYC
    }

    function test_TransferBlocked_AfterPartitionChange() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.prank(admin);
        token.mint(user1, 100 ether);

        // transfert OK initialement
        vm.prank(user1);
        token.transfer(user2, 10 ether);

        // on isole user2 dans RESTRICTED
        vm.prank(compliance);
        token.assignPartition(user2, RESTRICTED);

        // transfert doit échouer désormais
        vm.startPrank(user1);
        vm.expectRevert("Partition mismatch");
        token.transfer(user2, 1 ether);
        vm.stopPrank();
    }

    function test_ZeroAmountTransfer_Succeeds() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        vm.prank(user1);
        bool ok = token.transfer(user2, 0);
        assertTrue(ok);
    }

    function test_CanTransfer_ZeroAndZeroAddress() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        token.addToWhitelist(user2);
        vm.stopPrank();

        assertTrue(token.canTransfer(user1, user2, 0)); // même partition par défaut + KYC
        assertFalse(token.canTransfer(user1, address(0), 0));
    }

    function test_DocumentUpdate_Overrides() public {
        bytes32 name = keccak256("Prospectus");
        string memory uri1 = "ipfs://v1";
        string memory uri2 = "ipfs://v2";
        bytes32 h1 = keccak256("v1");
        bytes32 h2 = keccak256("v2");

        vm.startPrank(admin);
        token.addDocument(name, uri1, h1);
        (string memory u1, bytes32 hh1, uint256 t1) = token.getDocument(name);

        vm.warp(block.timestamp + 1);

        // update
        token.addDocument(name, uri2, h2);
        (string memory u2, bytes32 hh2, uint256 t2) = token.getDocument(name);
        vm.stopPrank();

        assertEq(u1, uri1);
        assertEq(hh1, h1);
        assertTrue(t2 > t1);

        assertEq(u2, uri2);
        assertEq(hh2, h2);
    }

    function test_Revert_UnauthorizedComplianceCalls() public {
        vm.expectRevert(); // missing role
        token.addToWhitelist(user1);

        vm.expectRevert(); // missing role
        token.assignPartition(user1, RESTRICTED);
    }

    function test_RoleRenounceAndRevoke() public {
        // Sanity: admin a bien DEFAULT_ADMIN_ROLE
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));

        // grant COMPLIANCE à user3 par l’admin
        vm.startPrank(admin);
        token.grantRole(token.COMPLIANCE_ROLE(), user3);
        vm.stopPrank();

        // Vérifier que user3 a le rôle avant de renoncer
        assertTrue(token.hasRole(token.COMPLIANCE_ROLE(), user3));

        // ⚠️ Utiliser startPrank/stopPrank (plus fiable que prank() ici)
        vm.startPrank(user3);
        token.renounceRole(token.COMPLIANCE_ROLE(), user3);
        vm.stopPrank();

        // user3 ne peut plus appeler des fonctions COMPLIANCE
        vm.prank(user3);
        vm.expectRevert();
        token.addToWhitelist(address(0xBEEF));

        // admin grant puis revoke
        vm.startPrank(admin);
        token.grantRole(token.COMPLIANCE_ROLE(), user3);
        token.revokeRole(token.COMPLIANCE_ROLE(), user3);
        vm.stopPrank();

        // user3 toujours bloqué
        vm.prank(user3);
        vm.expectRevert();
        token.assignPartition(address(0xBEEF), RESTRICTED);
    }

    function test_Property_StandardTransferCannotCreditNonKYC() public {
        vm.startPrank(compliance);
        token.addToWhitelist(user1);
        // user2 reste non-KYC
        vm.stopPrank();

        vm.prank(admin);
        token.mint(user1, 10 ether);

        vm.startPrank(user1);
        vm.expectRevert("Recipient not KYC-approved");
        token.transfer(user2, 1 ether);
        vm.stopPrank();
    }


    // ---------------------------------------------------------------
    // INVARIANT TESTS
    // ---------------------------------------------------------------

    /// @notice Invariant: totalSupply must equal sum of balances
    function invariant_TotalSupplyMatchesBalances() public {
        uint256 total;
        for (uint160 i = 1; i <= 6; i++) {
            total += token.balanceOf(address(i));
        }
        assertEq(total, token.totalSupply());
    }
}