// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title MockPriceOracle - A simple mock oracle for testing SecureVaultMultiToken
/// @author Mat
/// @notice Allows setting token prices in USD manually for local testing (1e18 precision)
contract MockPriceOracle {
    /// @notice Mapping from token address to USD price (1e18 precision)
    mapping(address => uint256) public prices;

    /// @notice Emitted when a token price is updated
    /// @param token The token whose price is updated
    /// @param price The new price in USD (1e18 precision)
    event PriceUpdated(address indexed token, uint256 price);

    /// @notice Sets the USD price for a given token (admin simulation)
    /// @dev In a real oracle, this would come from an external feed (Chainlink, Pyth, etc.)
    /// @param token The token address
    /// @param price The price in USD (1e18 precision)
    function setPrice(address token, uint256 price) external {
        require(token != address(0), "Invalid token");
        prices[token] = price;
        emit PriceUpdated(token, price);
    }

    /// @notice Returns the USD price of a given token
    /// @param token The token address
    /// @return The price in USD (1e18 precision)
    function getUSDPrice(address token) external view returns (uint256) {
        require(prices[token] > 0, "Price not set");
        return prices[token];
    }
}