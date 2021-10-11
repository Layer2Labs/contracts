pragma solidity >=0.4.24;

// Inheritance
import "synthetix-2.43.1/contracts/interfaces/IERC20.sol";
import "../interfaces/IExchangeRates.sol";

contract BinaryOptionParams {
    struct BomInitializeParams {
        address owner;
        address binaryOptionMastercopy;
        IERC20 sUSD;
        IExchangeRates exchangeRates;
        address creator;
        bytes32 oracleKey;
        uint strikePrice;
        uint[2] times; // [maturity, expiry]
        uint deposit; // sUSD deposit
        uint[2] fees; // [poolFee, creatorFee]
        bool customMarket;
        address iOracleInstanceAddress;
    }
}
