// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../../lib/forge-std/src/Test.sol";
import "../../contracts/SecureVaultMultiToken.sol";

/// @notice Mock ERC20 minimal pour tests
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

/// @notice Mock Oracle pour TVL
contract MockPriceOracle is IPriceOracle {
    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    function getUSDPrice(address token) external view override returns (uint256) {
        return prices[token];
    }
}

/// @notice Test suite SecureVaultMultiToken
contract SecureVaultMultiTokenTest is Test {
    SecureVaultMultiToken vault;
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockPriceOracle oracle;

    address admin = address(0xA);
    address investor = address(0xB);
    address auditor = address(0xC);
    address outsider = address(0xD);

    event Deposited(address indexed token, address indexed user, uint256 amount, uint256 total);
    event Withdrawn(address indexed token, address indexed user, uint256 amount, uint256 total);
    event EmergencyWithdrawal(address indexed token, address indexed user, uint256 amount, uint256 total);
    event DepositLimitUpdated(address indexed token, uint256 newLimit);
    event TokenWhitelisted(address indexed token, bool status);
    event OracleUpdated(address indexed newOracle);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        // Deploy vault & tokens
        vm.startPrank(admin);
        vault = new SecureVaultMultiToken();
        vm.stopPrank();

        tokenA = new MockERC20("TokenA", "TKA");
        tokenB = new MockERC20("TokenB", "TKB");

        // Mint to investor & approve
        tokenA.mint(investor, 1_000 ether);
        tokenB.mint(investor, 1_000 ether);

        vm.startPrank(investor);
        tokenA.approve(address(vault), type(uint256).max);
        tokenB.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        // Admin setup roles, whitelist & limits
        vm.startPrank(admin);
        vault.grantVaultRole(vault.INVESTOR_ROLE(), investor);
        vault.grantVaultRole(vault.AUDITOR_ROLE(), auditor);

        vault.setTokenWhitelist(address(tokenA), true);
        vault.setTokenWhitelist(address(tokenB), true);

        vault.setDepositLimit(address(tokenA), 500 ether);
        vault.setDepositLimit(address(tokenB), 1000 ether);

        vault.registerToken(address(tokenA));
        vault.registerToken(address(tokenB));
        vm.stopPrank();
    }

    /// --- DEPOTS ---
    function testDepositSuccess() public {
        vm.expectEmit(true, true, false, true);
        emit Deposited(address(tokenA), investor, 200 ether, 200 ether);

        vm.prank(investor);
        vault.deposit(address(tokenA), 200 ether);

        assertEq(vault.balances(address(tokenA), investor), 200 ether);
    }

    function testDepositExceedsLimit() public {
        vm.prank(investor);
        vm.expectRevert("Deposit limit exceeded");
        vault.deposit(address(tokenA), 600 ether);
    }

    function testDepositTokenNotWhitelisted() public {
        MockERC20 tokenC = new MockERC20("TokenC", "TKC");
        tokenC.mint(investor, 100 ether);
        vm.prank(investor);
        tokenC.approve(address(vault), 100 ether);

        vm.prank(investor);
        vm.expectRevert("Token not allowed");
        vault.deposit(address(tokenC), 50 ether);
    }

    function testDepositZeroAmount() public {
        vm.prank(investor);
        vm.expectRevert("Amount must be greater than 0");
        vault.deposit(address(tokenA), 0);
    }

    function testDepositWithoutInvestorRole() public {
        vm.prank(outsider);
        vm.expectRevert();
        vault.deposit(address(tokenA), 100 ether);
    }

    /// --- RETRAITS ---
    function testWithdrawSuccess() public {
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 200 ether);

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(address(tokenA), investor, 100 ether, 100 ether);

        vault.withdraw(address(tokenA), 100 ether);
        vm.stopPrank();

        assertEq(vault.balances(address(tokenA), investor), 100 ether);
    }

    function testWithdrawTooMuch() public {
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 200 ether);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(address(tokenA), 500 ether);
        vm.stopPrank();
    }

    function testWithdrawZero() public {
        vm.prank(investor);
        vm.expectRevert("Amount must be greater than 0");
        vault.withdraw(address(tokenA), 0);
    }

    /// --- EMERGENCY WITHDRAW ---
    function testEmergencyWithdrawPaused() public {
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 150 ether);
        vm.stopPrank();

        vm.prank(admin);
        vault.pause();

        vm.expectEmit(true, true, false, true);
        emit EmergencyWithdrawal(address(tokenA), investor, 150 ether, 0);

        vm.prank(investor);
        vault.emergencyWithdraw(address(tokenA));

        assertEq(vault.balances(address(tokenA), investor), 0);
    }

    function testEmergencyWithdrawNoFunds() public {
        vm.prank(admin);
        vault.pause();
        vm.prank(investor);
        vm.expectRevert("No funds to withdraw");
        vault.emergencyWithdraw(address(tokenA));
    }

    function testEmergencyWithdrawNotPaused() public {
        vm.prank(investor);
        vault.deposit(address(tokenA), 100 ether);
        vm.prank(investor);
        vm.expectRevert("Pausable: not paused");
        vault.emergencyWithdraw(address(tokenA));
    }

    /// --- ADMIN PAUSE ---
    function testPauseUnpauseAdminOnly() public {
        vm.prank(outsider);
        vm.expectRevert();
        vault.pause();

        vm.prank(admin);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(admin);
        vault.unpause();
        assertFalse(vault.paused());
    }

    /// --- LIMITES ---
    function testSetDepositLimit() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit DepositLimitUpdated(address(tokenA), 800 ether);
        vault.setDepositLimit(address(tokenA), 800 ether);
        assertEq(vault.depositLimitPerToken(address(tokenA)), 800 ether);
    }

    function testSetDepositLimitsBatch() public {
        address[] memory tokens = new address[](2);
        uint256[] memory limits = new uint256[](2);

        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        limits[0] = 300 ether;
        limits[1] = 400 ether;

        vm.prank(admin);
        vault.setDepositLimits(tokens, limits);

        assertEq(vault.depositLimitPerToken(address(tokenA)), 300 ether);
        assertEq(vault.depositLimitPerToken(address(tokenB)), 400 ether);
    }

    /// --- WHITELIST & TOKENS ---
    function testSetTokenWhitelist() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit TokenWhitelisted(address(tokenA), false);
        vault.setTokenWhitelist(address(tokenA), false);
        assertFalse(vault.isTokenWhitelisted(address(tokenA)));
    }

    function testRegisterToken() public {
        MockERC20 tokenC = new MockERC20("TokenC", "TKC");
        vm.prank(admin);
        vault.registerToken(address(tokenC));
        assertTrue(vault.isTokenRegistered(address(tokenC)));
    }

    function testRegisterTokenAlreadyRegistered() public {
        vm.prank(admin);
        vm.expectRevert("Already registered");
        vault.registerToken(address(tokenA));
    }

    /// --- ORACLE & TVL ---
    function testSetOracleAndTVL() public {
        oracle = new MockPriceOracle();
        vm.prank(admin);
        vault.setOracle(address(oracle));

        oracle.setPrice(address(tokenA), 2e18); // $2
        oracle.setPrice(address(tokenB), 1e18); // $1

        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether); // $200
        vault.deposit(address(tokenB), 300 ether); // $300
        vm.stopPrank();

        uint256 tvl = vault.totalValueLocked();
        assertEq(tvl, 500 ether); // $500
    }

    function testTVLRevertIfNoOracle() public {
        vm.expectRevert("Oracle not set");
        vault.totalValueLocked();
    }

    /// --- VIEW BALANCE & AUDIT ---
    function testViewBalanceAuditor() public {
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether);
        vm.stopPrank();

        vm.prank(auditor);
        assertEq(vault.viewBalance(address(tokenA), investor), 100 ether);
    }

    function testViewBalanceWithoutAuditorRole() public {
        vm.prank(outsider);
        vm.expectRevert();
        vault.viewBalance(address(tokenA), investor);
    }

    function testGetMyBalanceInvestorOnly() public {
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether);
        assertEq(vault.getMyBalance(address(tokenA)), 100 ether);
        vm.stopPrank();

        vm.prank(outsider);
        vm.expectRevert();
        vault.getMyBalance(address(tokenA));
    }

    /// --- RECOVER ERC20 ---
    function testRecoverERC20ByAdmin() public {
        MockERC20 tokenC = new MockERC20("TokenC", "TKC");
        tokenC.mint(address(vault), 50 ether);

        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(vault), admin, 50 ether);

        vault.recoverERC20(address(tokenC), 50 ether);
    }

    function testRecoverERC20RevertIfActiveToken() public {
        vm.prank(admin);
        vm.expectRevert("Cannot recover active vault token");
        vault.recoverERC20(address(tokenA), 10 ether);
    }

    function testRecoverERC20ByNonAdmin() public {
        MockERC20 tokenC = new MockERC20("TokenC", "TKC");
        tokenC.mint(address(vault), 50 ether);

        vm.prank(outsider);
        vm.expectRevert();
        vault.recoverERC20(address(tokenC), 50 ether);
    }

        /// --- BATCH LIMITS ---
    function testSetDepositLimitsBatchLengthMismatch() public {
        address[] memory tokens = new address[](2);
        uint256[] memory limits = new uint256[](1);

        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        limits[0] = 300 ether;

        vm.prank(admin);
        vm.expectRevert("Length mismatch");
        vault.setDepositLimits(tokens, limits);
    }

    /// --- INVALID INPUTS ---
    function testSetDepositLimitInvalidToken() public {
        vm.prank(admin);
        vm.expectRevert("Invalid token address");
        vault.setDepositLimit(address(0), 500 ether);
    }

    function testSetDepositLimitsBatchInvalidToken() public {
        address[] memory tokens = new address[](2);
        uint256[] memory limits = new uint256[](2);

        tokens[0] = address(0); // invalid token
        limits[0] = 100 ether;

        vm.prank(admin);
        vm.expectRevert("Invalid token address");
        vault.setDepositLimits(tokens, limits);
    }

    function testSetTokenWhitelistInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert("Invalid token address");
        vault.setTokenWhitelist(address(0), true);
    }

    function testRegisterTokenInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert("Invalid token");
        vault.registerToken(address(0));
    }

    function testSetOracleInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert("Invalid oracle");
        vault.setOracle(address(0));
    }

    /// --- ORACLE & TVL EDGE CASES ---
    function testTVLSkipUnwhitelistedToken() public {
        oracle = new MockPriceOracle();
        vm.prank(admin);
        vault.setOracle(address(oracle));

        oracle.setPrice(address(tokenA), 1e18);
        oracle.setPrice(address(tokenB), 1e18);

        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether);
        vault.deposit(address(tokenB), 100 ether);
        vm.stopPrank();

        // Remove tokenB from whitelist
        vm.prank(admin);
        vault.setTokenWhitelist(address(tokenB), false);

        // TVL should only include tokenA
        uint256 tvl = vault.totalValueLocked();
        assertEq(tvl, 100 ether);
    }

    function testTVLSkipZeroDepositToken() public {
        oracle = new MockPriceOracle();
        vm.prank(admin);
        vault.setOracle(address(oracle));

        oracle.setPrice(address(tokenA), 1e18);
        oracle.setPrice(address(tokenB), 1e18);

        // Only deposit tokenA
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether);
        vm.stopPrank();

        // tokenB is registered but zero deposit
        uint256 tvl = vault.totalValueLocked();
        assertEq(tvl, 100 ether);
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

    /// --- INVALID RECOVER ---
    function testRecoverERC20InvalidTokenAddress() public {
        vm.prank(admin);
        vm.expectRevert();
        vault.recoverERC20(address(0), 10 ether); // Should revert with low-level error
    }

        /// --- SCENARIO COMPLET MULTITOKEN ---
    function testEndToEndMultiTokenScenario() public {
        // ✅ 1. Setup de l'oracle et des prix
        oracle = new MockPriceOracle();
        vm.prank(admin);
        vault.setOracle(address(oracle));

        oracle.setPrice(address(tokenA), 2e18); // $2/tokenA
        oracle.setPrice(address(tokenB), 1e18); // $1/tokenB

        // ✅ 2. Investor dépose TokenA et TokenB
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 200 ether); // $400
        vault.deposit(address(tokenB), 300 ether); // $300
        vm.stopPrank();

        // Vérif des balances
        assertEq(vault.balances(address(tokenA), investor), 200 ether);
        assertEq(vault.balances(address(tokenB), investor), 300 ether);

        // Vérif TVL (400 + 300 = $700)
        assertEq(vault.totalValueLocked(), 700 ether);

        // ✅ 3. Admin met en pause le vault
        vm.prank(admin);
        vault.pause();
        assertTrue(vault.paused());

        // ✅ 4. Emergency withdraw pour TokenA uniquement
        vm.prank(investor);
        vault.emergencyWithdraw(address(tokenA));
        assertEq(vault.balances(address(tokenA), investor), 0);

        // ✅ 5. Unpause par l'admin
        vm.prank(admin);
        vault.unpause();
        assertFalse(vault.paused());

        // ✅ 6. Investor redépose TokenA et retire TokenB
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 100 ether); // nouveau dépôt
        vault.withdraw(address(tokenB), 100 ether); // retrait partiel
        vm.stopPrank();

        // Vérifs post-opérations
        assertEq(vault.balances(address(tokenA), investor), 100 ether);
        assertEq(vault.balances(address(tokenB), investor), 200 ether);

        // ✅ 7. TVL après mises à jour (TokenA $2*100 + TokenB $1*200 = $400)
        uint256 tvl = vault.totalValueLocked();
        assertEq(tvl, 400 ether);

        // ✅ 8. Investor retire le reste et vérifie retour aux soldes initiaux
        vm.startPrank(investor);
        vault.withdraw(address(tokenA), 100 ether);
        vault.withdraw(address(tokenB), 200 ether);
        vm.stopPrank();

        assertEq(vault.balances(address(tokenA), investor), 0);
        assertEq(vault.balances(address(tokenB), investor), 0);
    }

        /// --- SCENARIO MULTITOKEN AVEC RETRAIT DE WHITELIST ---
    function testEndToEndMultiTokenWithWhitelistRemoval() public {
        // ✅ 1. Setup oracle et prix
        oracle = new MockPriceOracle();
        vm.prank(admin);
        vault.setOracle(address(oracle));

        oracle.setPrice(address(tokenA), 2e18); // $2
        oracle.setPrice(address(tokenB), 1e18); // $1

        // ✅ 2. Investor dépose TokenA et TokenB
        vm.startPrank(investor);
        vault.deposit(address(tokenA), 150 ether); // $300
        vault.deposit(address(tokenB), 200 ether); // $200
        vm.stopPrank();

        // Vérif balances initiales
        assertEq(vault.balances(address(tokenA), investor), 150 ether);
        assertEq(vault.balances(address(tokenB), investor), 200 ether);
        assertEq(vault.totalValueLocked(), 500 ether); // $300 + $200

        // ✅ 3. Admin retire TokenB de la whitelist
        vm.prank(admin);
        vault.setTokenWhitelist(address(tokenB), false);
        assertFalse(vault.isTokenWhitelisted(address(tokenB)));

        // ✅ 4. Tentative de dépôt TokenB doit échouer
        vm.startPrank(investor);
        vm.expectRevert("Token not allowed");
        vault.deposit(address(tokenB), 50 ether);
        vm.stopPrank();

        // ✅ 5. Investor peut encore retirer son solde TokenB
        vm.startPrank(investor);
        vault.withdraw(address(tokenB), 100 ether);
        vm.stopPrank();

        assertEq(vault.balances(address(tokenB), investor), 100 ether);

        // ✅ 6. Vérifier que TVL ignore désormais TokenB non-whitelisté
        uint256 tvl = vault.totalValueLocked();
        // TVL inclut uniquement TokenA car TokenB est unwhitelisted
        assertEq(tvl, 150 ether * 2e18 / 1e18); // $300

        // ✅ 7. Investor retire le reste de TokenB et TokenA
        vm.startPrank(investor);
        vault.withdraw(address(tokenB), 100 ether); // TokenB complet
        vault.withdraw(address(tokenA), 150 ether); // TokenA complet
        vm.stopPrank();

        assertEq(vault.balances(address(tokenA), investor), 0);
        assertEq(vault.balances(address(tokenB), investor), 0);
    }
}