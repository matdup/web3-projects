// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/StdCheats.sol";
import "../../contracts/SecureVault.sol";

// Unit test suite for SecureVault smart contract
contract SecureVaultTest is Test {
    SecureVault vault;
    MockERC20 token;

    // local events redeclaration for expectEmit
    event Deposited(address indexed user, uint256 amount, uint256 total);
    event Withdrawn(address indexed user, uint256 amount, uint256 total);
    event EmergencyWithdrawal(address indexed user, uint256 amount, uint256 total);
    event DepositLimitUpdated(uint256 newLimit);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Define test actors
    address admin = address(0xA);
    address investor = address(0xB);
    address outsider = address(0xC);

    // Initial token supply and deposit limit for the test
    uint256 initialSupply = 1_000_000 ether;
    uint256 depositLimit = 1_000 ether;

    // Runs before every test
    function setUp() public {
        // Deploy mock ERC20 token and mint to investor
        token = new MockERC20("Test Token", "TST");
        token.mint(investor, initialSupply);

        // Deploy the vault and assign roles
        vm.startPrank(admin);
        vault = new SecureVault(address(token), depositLimit);
        vault.grantRole(vault.INVESTOR_ROLE(), investor);
        vm.stopPrank();

        // Investor approves unlimited token allowance to the vault
        vm.prank(investor);
        token.approve(address(vault), type(uint256).max);
    }

    // ✅ Successful deposit by investor
    function testDepositSuccess() public {
        vm.expectEmit(true, true, false, true);
        emit Deposited(investor, 500 ether, 500 ether);

        vm.prank(investor);
        vault.deposit(500 ether);

        assertEq(vault.balances(investor), 500 ether);
    }

    // ❌ Deposit exceeding the limit should revert
    function testDepositExceedsLimit() public {
        vm.prank(investor);
        vm.expectRevert("Deposit limit exceeded");
        vault.deposit(2_000 ether);
    }

    // ❌ Deposit without INVESTOR_ROLE should revert
    function testDepositWithoutRole() public {
        vm.prank(outsider);
        token.mint(outsider, 100 ether);
        token.approve(address(vault), 100 ether);
        vm.expectRevert();
        vault.deposit(100 ether);
    }

    // ❌ Deposit of 0 tokens
    function testDepositZeroAmount() public {
        vm.prank(investor);
        vm.expectRevert("Amount must be greater than 0");
        vault.deposit(0);
    }

    // ✅ Withdraw after deposit should work and update balances
    function testWithdrawSuccess() public {
        vm.prank(investor);
        vault.deposit(500 ether);

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(investor, 200 ether, 300 ether);

        vm.prank(investor);
        vault.withdraw(200 ether);

        assertEq(vault.balances(investor), 300 ether);
        assertEq(token.balanceOf(investor), initialSupply - 500 ether + 200 ether);
    }

    // ❌ Attempting to withdraw more than deposited should revert
    function testWithdrawTooMuch() public {
        vm.prank(investor);
        vault.deposit(300 ether);

        vm.prank(investor);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(500 ether);
    }

    // ❌ Attempting to withdraw 0 tokens
    function testWithdrawZeroAmount() public {
        vm.prank(investor);
        vault.deposit(300 ether);

        vm.prank(investor);
        vm.expectRevert("Amount must be greater than 0");
        vault.withdraw(0);
    }

    // ✅ Emergency withdraw only works when paused and investor has funds
    function testPauseAndEmergencyWithdraw() public {
    // Ensure investor has the INVESTOR_ROLE (done by the admin)
    vm.startPrank(admin);
    vault.grantRole(vault.INVESTOR_ROLE(), investor);
    vm.stopPrank();

    // Investor deposits some tokens
    vm.prank(investor);
    vault.deposit(100 ether);

    // Admin pauses the vault
    vm.prank(admin);
    vault.pause();

    vm.expectEmit(true, true, false, true);
    emit EmergencyWithdrawal(investor, 100 ether, 0 ether);

    // Investor performs emergency withdrawal
    vm.prank(investor);
    vault.emergencyWithdraw();

    // Assertions
    assertEq(vault.balances(investor), 0);
    assertEq(token.balanceOf(investor), initialSupply);
    }

    // ❌ Emergency withdraw without balance
    function testEmergencyWithdrawWithoutBalance() public {
        vm.prank(admin);
        vault.pause();

        vm.prank(investor);
        vm.expectRevert("No funds to withdraw");
        vault.emergencyWithdraw();
    }

    // ❌ Emergency withdraw not paused
    function testEmergencyWithdrawNotPaused() public {
        vm.prank(investor);
        vault.deposit(50 ether);

        vm.prank(investor);
        vm.expectRevert("Pausable: not paused");
        vault.emergencyWithdraw();
    }

    // ❌ Only admin should be able to pause the contract
    function testPauseOnlyAdmin() public {
        vm.prank(outsider);
        vm.expectRevert();
        vault.pause();
    }

    // ❌ Unpause par non-admin
    function testUnpauseOnlyAdmin() public {
        vm.prank(admin);
        vault.pause();

        vm.prank(outsider);
        vm.expectRevert();
        vault.unpause();
    }

    // ✅ setDepositLimit fonctionne
    function testSetDepositLimit() public {
        vm.expectEmit(false, false, false, true);
        emit DepositLimitUpdated(2_000 ether);

        vm.prank(admin);
        vault.setDepositLimit(2_000 ether);

        vm.prank(investor);
        vault.deposit(2_000 ether);

        assertEq(vault.balances(investor), 2_000 ether);
    }

    // ✅ Grant / Revoke Role
    function testGrantAndRevokeInvestorRole() public {
        //Vérification initiale : L'outsider ne doit pas avoir le rôle INVESTOR_ROLE
        assertFalse(vault.hasRole(vault.INVESTOR_ROLE(), outsider), "Outsider should not have the INVESTOR_ROLE initially");
        
        // Admin grant INVESTOR role to outsider
        vm.startPrank(admin);
        vault.grantVaultRole(vault.INVESTOR_ROLE(), outsider);
        vm.stopPrank();

        // Vérifiez que l'outsider a bien le rôle
        assertTrue(vault.hasRole(vault.INVESTOR_ROLE(), outsider), "Outsider should have the INVESTOR_ROLE after granting");

        // Outsider attempt a deposit
        vm.startPrank(outsider);
        token.mint(outsider, 100 ether);
        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();

        // Admin withraw the role
        vm.startPrank(admin);
        vault.revokeVaultRole(vault.INVESTOR_ROLE(), outsider);
        vm.stopPrank();

        // Vérifier que l'outsider n'a plus le rôle
        assertFalse(vault.hasRole(vault.INVESTOR_ROLE(), outsider), "Outsider should not have the INVESTOR_ROLE after revoking");
        
        // Outsider attempt to do a deposit
        vm.startPrank(outsider);
        vm.expectRevert("AccessControl: account 0x000000000000000000000000000000000000000c is missing role 0xb165298935924f540e4181c03493a5d686c54a0aaeb3f6216de85b7ffbba7738");
        vault.deposit(100 ether);  // Cette action doit échouer
        vm.stopPrank();
    }

    // ❌ Double pause / unpause
    function testDoublePauseAndUnpause() public {
        // first pause by admin
        vm.prank(admin);
        vault.pause();

        // second pause attempt
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        vault.pause();

        // First unpause by admin
        vm.prank(admin);
        vault.unpause();

        // second unpause attempt
        vm.prank(admin);
        vm.expectRevert("Pausable: not paused");
        vault.unpause();
    }

    // ✅ Test getMyBalance
    function testGetMyBalance() public {
        vm.prank(investor);
        vault.deposit(300 ether);
        vm.prank(investor);
        assertEq(vault.getMyBalance(), 300 ether);
    }

    // ❌ getMyBalance revert sans rôle INVESTOR
    function testGetMyBalanceWithoutRole() public {
        vm.expectRevert();
        vault.getMyBalance();
    }

    // ✅ Test viewBalance pour AUDITOR
    function testViewBalanceAuditor() public {
        vm.startPrank(admin);
        vault.grantVaultRole(vault.AUDITOR_ROLE(), outsider);
        vm.stopPrank();

        vm.prank(investor);
        vault.deposit(200 ether);

        vm.prank(outsider);
        assertEq(vault.viewBalance(investor), 200 ether);
    }

    // ❌ viewBalance revert sans rôle AUDITOR
    function testViewBalanceWithoutAuditorRole() public {
        vm.prank(investor);
        vault.deposit(200 ether);

        vm.expectRevert();
        vm.prank(outsider);
        vault.viewBalance(investor);
    }

    // ✅ Test recoverERC20 par admin
    function testRecoverERC20ByAdmin() public {
        MockERC20 otherToken = new MockERC20("Other", "OTH");
        otherToken.mint(address(vault), 500 ether);

        vm.prank(admin);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(vault), admin, 500 ether);

        vault.recoverERC20(address(otherToken), 500 ether);

        assertEq(otherToken.balanceOf(admin), 500 ether);
    }

    // ❌ recoverERC20 par outsider
    function testRecoverERC20ByNonAdmin() public {
        MockERC20 otherToken = new MockERC20("Other", "OTH");
        otherToken.mint(address(vault), 500 ether);

        vm.prank(outsider);
        vm.expectRevert();
        vault.recoverERC20(address(otherToken), 500 ether);
    }

    // ❌ recoverERC20 avec le token du vault
    function testRecoverVaultTokenShouldRevert() public {
        vm.prank(admin);
        vm.expectRevert("Cannot recover vault token");
        vault.recoverERC20(address(token), 100 ether);
    }

        /// --- LIMITES ---
    function testSetDepositLimitByNonAdmin() public {
        vm.prank(outsider);
        vm.expectRevert();
        vault.setDepositLimit(2000 ether);
    }

    function testSetDepositLimitZero() public {
        vm.prank(admin);
        vault.setDepositLimit(0);

        vm.prank(investor);
        vm.expectRevert("Deposit limit exceeded");
        vault.deposit(1 ether);
    }

    /// --- RECOVER ERC20 ---
    function testRecoverERC20InvalidTokenAddress() public {
        vm.prank(admin);
        vm.expectRevert();
        vault.recoverERC20(address(0), 100 ether);
    }

    /// --- EMERGENCY WITHDRAW ---
    function testEmergencyWithdrawAfterUnpauseReverts() public {
        vm.startPrank(investor);
        vault.deposit(100 ether);
        vm.stopPrank();

        vm.prank(admin);
        vault.pause();
        vm.prank(admin);
        vault.unpause();

        vm.prank(investor);
        vm.expectRevert("Pausable: not paused");
        vault.emergencyWithdraw();
    }

    /// --- GET BALANCES ---
    function testViewBalanceWithAuditorRole() public {
        vm.startPrank(admin);
        vault.grantVaultRole(vault.AUDITOR_ROLE(), outsider);
        vm.stopPrank();

        vm.prank(investor);
        vault.deposit(200 ether);

        vm.prank(outsider);
        uint256 balance = vault.viewBalance(investor);
        assertEq(balance, 200 ether);
    }

    function testViewBalanceWithoutAuditorRoleReverts() public {
        vm.prank(investor);
        vault.deposit(200 ether);

        vm.prank(outsider);
        vm.expectRevert();
        vault.viewBalance(investor);
    }

    /// --- ROLES ---
    function testGrantRevokeAuditorRole() public {
        assertFalse(vault.hasRole(vault.AUDITOR_ROLE(), outsider));

        vm.startPrank(admin);
        vault.grantVaultRole(vault.AUDITOR_ROLE(), outsider);
        assertTrue(vault.hasRole(vault.AUDITOR_ROLE(), outsider));

        vault.revokeVaultRole(vault.AUDITOR_ROLE(), outsider);
        vm.stopPrank();
        assertFalse(vault.hasRole(vault.AUDITOR_ROLE(), outsider));
    }

    function testGrantRoleByNonAdminReverts() public {
        bytes32 investorRole = vault.INVESTOR_ROLE();

        vm.prank(outsider);
        vm.expectRevert();
        vault.grantVaultRole(investorRole, outsider);

        assertFalse(vault.hasRole(investorRole, outsider));
    }

    function testRevokeRoleByNonAdminReverts() public {
        bytes32 investorRole = vault.INVESTOR_ROLE();

        // Grant role first
        vm.startPrank(admin);
        vault.grantVaultRole(investorRole, outsider);
        vm.stopPrank();

        // Try revoke without admin rights
        vm.prank(outsider);
        vm.expectRevert();
        vault.revokeVaultRole(investorRole, outsider);

        assertTrue(vault.hasRole(investorRole, outsider));
    }

    /// --- MULTIPLE DEPOSITS ---
    function testMultipleDepositsUntilLimit() public {
        vm.startPrank(investor);
        vault.deposit(400 ether);
        vault.deposit(600 ether);
        assertEq(vault.balances(investor), 1000 ether);

        vm.expectRevert("Deposit limit exceeded");
        vault.deposit(1 ether);
        vm.stopPrank();
    }

    /// --- WITHDRAW EDGE CASE ---
    function testWithdrawFullBalance() public {
        vm.prank(investor);
        vault.deposit(500 ether);

        vm.prank(investor);
        vault.withdraw(500 ether);

        assertEq(vault.balances(investor), 0);
        assertEq(token.balanceOf(investor), initialSupply);
    }

    /// --- REENTRANCY SAFETY ---
    function testReentrancyOnWithdraw() public {
        vm.startPrank(investor);
        vault.deposit(2 ether);

        // Premier retrait normal
        vault.withdraw(1 ether);

        // Tentative de réentrance immédiatement après
        vm.expectRevert("ReentrancyGuard: reentrant call");
        address(vault).call(
            abi.encodeWithSignature("withdraw(uint256)", 1 ether)
        );
        vm.stopPrank();
    }

    /// --- SCENARIO COMPLET END-TO-END ---
    function testEndToEndScenario() public {
        // ✅ 1. Dépôt initial par l'investor
        vm.startPrank(investor);
        vault.deposit(500 ether);
        assertEq(vault.balances(investor), 500 ether);
        assertEq(vault.getMyBalance(), 500 ether);
        vm.stopPrank();

        // ✅ 2. Admin met en pause le vault (maintenance ou urgence)
        vm.prank(admin);
        vault.pause();
        assertTrue(vault.paused());

        // ✅ 3. Emergency withdraw pendant la pause
        vm.prank(investor);
        vault.emergencyWithdraw();
        assertEq(vault.balances(investor), 0); 
        assertEq(token.balanceOf(investor), initialSupply); // récupération complète

        // ✅ 4. Admin réactive le vault
        vm.prank(admin);
        vault.unpause();
        assertFalse(vault.paused());

        // ✅ 5. Investor redépose après unpause
        vm.startPrank(investor);
        vault.deposit(300 ether);
        assertEq(vault.balances(investor), 300 ether);

        // ✅ 6. Investor retire partiellement
        vault.withdraw(100 ether);
        assertEq(vault.balances(investor), 200 ether);

        // ✅ 7. Investor retire le reste (solde complet)
        vault.withdraw(200 ether);
        assertEq(vault.balances(investor), 0);

        // ✅ Vérification finale : solde token restauré intégralement
        assertEq(token.balanceOf(investor), initialSupply);
        vm.stopPrank();
    }
}

// Mock implementation of a minimal ERC20 token used for testing
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // Mint new tokens to an address
    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    // Transfer tokens between accounts
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Transfer from an approved allowance
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Approve an address to spend tokens on your behalf
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

}



