pragma solidity ^0.5.16;

// Inheritance
import "synthetix-2.43.1/contracts/MinimalProxyFactory.sol";
import "synthetix-2.43.1/contracts/Owned.sol";

// Internal references
import "./BinaryOptionMarket.sol";
import "synthetix-2.43.1/contracts/interfaces/IExchangeRates.sol";
import "synthetix-2.43.1/contracts/interfaces/IERC20.sol";
import "../interfaces/IBinaryOptionMarket.sol";

import "synthetix-2.43.1/contracts/interfaces/IExchangeRates.sol";
import "synthetix-2.43.1/contracts/interfaces/IERC20.sol";

contract BinaryOptionMarketFactory is MinimalProxyFactory, Owned, IBinaryOptionMarket {
    /* ========== STATE VARIABLES ========== */
    address public binaryOptionMarketManager;
    address public binaryOptionMarketMastercopy;
    address public binaryOptionMastercopy;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner) public MinimalProxyFactory() Owned(_owner) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        address creator,
        IERC20 sUSD,
        IExchangeRates exchangeRates,
        bytes32 oracleKey,
        uint strikePrice,
        uint[2] calldata times, // [maturity, expiry]
        uint initialMint,
        uint[2] calldata fees, // [poolFee, creatorFee]
        bool customMarket,
        address customOracle
    ) external returns (BinaryOptionMarket) {
        require(binaryOptionMarketManager == msg.sender, "Only permitted by the manager.");

        BinaryOptionMarket bom = BinaryOptionMarket(
            _cloneAsMinimalProxy(binaryOptionMarketMastercopy, "Could not create a Binary Option Market")
        );
        bom.initialize(
            BomInitializeParams(
                binaryOptionMarketManager,
                binaryOptionMastercopy,
                sUSD,
                exchangeRates,
                creator,
                oracleKey,
                strikePrice,
                times,
                initialMint,
                fees,
                customMarket,
                customOracle
            )
        );
        return bom;
    }

    /* ========== SETTERS ========== */
    function setBinaryOptionMarketManager(address _binaryOptionMarketManager) external onlyOwner {
        binaryOptionMarketManager = _binaryOptionMarketManager;
        emit BinaryOptionMarketManagerChanged(_binaryOptionMarketManager);
    }

    function setBinaryOptionMarketMastercopy(address _binaryOptionMarketMastercopy) external onlyOwner {
        binaryOptionMarketMastercopy = _binaryOptionMarketMastercopy;
        emit BinaryOptionMarketMastercopyChanged(_binaryOptionMarketMastercopy);
    }

    function setBinaryOptionMastercopy(address _binaryOptionMastercopy) external onlyOwner {
        binaryOptionMastercopy = _binaryOptionMastercopy;
        emit BinaryOptionMastercopyChanged(_binaryOptionMastercopy);
    }

    event BinaryOptionMarketManagerChanged(address _binaryOptionMarketManager);
    event BinaryOptionMarketMastercopyChanged(address _binaryOptionMarketMastercopy);
    event BinaryOptionMastercopyChanged(address _binaryOptionMastercopy);
}
