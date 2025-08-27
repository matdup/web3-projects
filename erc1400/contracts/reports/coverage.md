m@MacBook-Pro contracts % forge coverage
Warning: optimizer settings and `viaIR` have been disabled for accurate coverage reports.
If you encounter "stack too deep" errors, consider using `--ir-minimum` which enables `viaIR` with minimum optimization resolving most of the errors
[⠊] Compiling...
[⠃] Compiling 35 files with Solc 0.8.25
[⠊] Solc 0.8.25 finished in 2.91s
Compiler run successful with warnings:
Warning (2018): Function state mutability can be restricted to view
   --> test/ERC1400Token.t.sol:604:5:
    |
604 |     function invariant_TotalSupplyMatchesBalances() public {
    |     ^ (Relevant source part starts here and spans across multiple lines).

Analysing contracts...
Running tests...

Ran 2 tests for test/Counter.t.sol:CounterTest
[PASS] testFuzz_SetNumber(uint256) (runs: 256, μ: 28978, ~: 29289)
[PASS] test_Increment() (gas: 28784)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 5.37ms (5.12ms CPU time)

Ran 38 tests for test/ERC1400Token.t.sol:ERC1400TokenTest
[PASS] invariant_TotalSupplyMatchesBalances() (runs: 256, calls: 128000, reverts: 118871)
[PASS] testAddAndRemoveDocument() (gas: 76053)
[PASS] testAddToWhitelistAndDefaultPartition() (gas: 68943)
[PASS] testAssignPartition() (gas: 70082)
[PASS] testForceTransferByRegulator() (gas: 210841)
[PASS] testFuzzMintTransfer(uint256) (runs: 256, μ: 183318, ~: 183318)
[PASS] testFuzzPartitionIsolation(bytes32,bytes32) (runs: 256, μ: 186761, ~: 186761)
[PASS] testMintAndTransferWithinPartition() (gas: 202716)
[PASS] test_ApproveAndTransferFrom_Compliant() (gas: 215804)
[PASS] test_BurnTokens() (gas: 127862)
[PASS] test_CanTransferByPartitionChecks() (gas: 194601)
[PASS] test_CanTransferChecks() (gas: 185088)
[PASS] test_CanTransfer_ZeroAndZeroAddress() (gas: 126459)
[PASS] test_DocumentUpdate_Overrides() (gas: 104114)
[PASS] test_Event_ForcedTransfer() (gas: 163930)
[PASS] test_Events_DocAddRemove() (gas: 71641)
[PASS] test_Events_WhitelistAndPartition() (gas: 72981)
[PASS] test_ForceTransfer_IgnoresKYCAndPartition() (gas: 160293)
[PASS] test_Property_StandardTransferCannotCreditNonKYC() (gas: 129383)
[PASS] test_RemoveFromWhitelist() (gas: 53109)
[PASS] test_RevertWhen_AddDocumentWithEmptyURI() (gas: 15933)
[PASS] test_RevertWhen_AddToWhitelistWithZeroAddress() (gas: 14824)
[PASS] test_RevertWhen_AssignPartitionWithZeroPartition() (gas: 67176)
[PASS] test_RevertWhen_AssignPartitionWithoutKYC() (gas: 19498)
[PASS] test_RevertWhen_ForceTransferInvalidAddress() (gas: 132350)
[PASS] test_RevertWhen_MintToNonWhitelisted() (gas: 24690)
[PASS] test_RevertWhen_RemoveFromWhitelistWithZeroAddress() (gas: 14805)
[PASS] test_RevertWhen_RemoveNonExistentDocument() (gas: 17024)
[PASS] test_RevertWhen_TransferDifferentPartitions() (gas: 181844)
[PASS] test_RevertWhen_TransferToZeroAddress() (gas: 124927)
[PASS] test_RevertWhen_UnauthorizedForceTransfer() (gas: 178754)
[PASS] test_Revert_TransferFrom_AllowanceExceeded() (gas: 208221)
[PASS] test_Revert_TransferFrom_NonKYCRecipient() (gas: 159839)
[PASS] test_Revert_TransferFrom_PartitionMismatch() (gas: 211971)
[PASS] test_Revert_UnauthorizedComplianceCalls() (gas: 18526)
[PASS] test_RoleRenounceAndRevoke() (gas: 73830)
[PASS] test_TransferBlocked_AfterPartitionChange() (gas: 211005)
[PASS] test_ZeroAmountTransfer_Succeeds() (gas: 126280)
Suite result: ok. 38 passed; 0 failed; 0 skipped; finished in 2.25s (2.31s CPU time)

Ran 2 test suites in 2.25s (2.26s CPU time): 40 tests passed, 0 failed, 0 skipped (40 total tests)

╭--------------------------------+-----------------+-----------------+-----------------+-----------------╮
| File                           | % Lines         | % Statements    | % Branches      | % Funcs         |
+========================================================================================================+
| script/Counter.s.sol           | 0.00% (0/5)     | 0.00% (0/3)     | 100.00% (0/0)   | 0.00% (0/2)     |
|--------------------------------+-----------------+-----------------+-----------------+-----------------|
| src/Counter.sol                | 100.00% (4/4)   | 100.00% (2/2)   | 100.00% (0/0)   | 100.00% (2/2)   |
|--------------------------------+-----------------+-----------------+-----------------+-----------------|
| src/contracts/ERC1400Token.sol | 100.00% (65/65) | 100.00% (56/56) | 100.00% (29/29) | 100.00% (17/17) |
|--------------------------------+-----------------+-----------------+-----------------+-----------------|
| Total                          | 93.24% (69/74)  | 95.08% (58/61)  | 100.00% (29/29) | 90.48% (19/21)  |
╰--------------------------------+-----------------+-----------------+-----------------+-----------------╯
m@MacBook-Pro contracts % 