pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Inheritance
import "synthetix-2.50.4-ovm/contracts/MinimalProxyFactory.sol";
import "synthetix-2.50.4-ovm/contracts/Owned.sol";

// Internal references
import "./ThalesRoyalePrivate.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IBinaryOptionMarket.sol";
import "synthetix-2.50.4-ovm/contracts/interfaces/IERC20.sol";

contract ThalesRoyalePrivateFactory is MinimalProxyFactory, Owned {

    /* ========== STATE VARIABLES ========== */

    address public thalesRoyalePrivateManager;
    address public thalesRoyalePrivateMastercopy;
    address public zeroExAddress;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner) public MinimalProxyFactory() Owned(_owner) {}


    /* ========== MUTATIVE FUNCTIONS ========== */

    function createRoyale(
        address creator
        ) external returns (ThalesRoyalePrivate) {
        require(thalesRoyalePrivateManager == msg.sender, "Only permitted by the manager.");

        ThalesRoyalePrivate trp = ThalesRoyalePrivate(
            _cloneAsMinimalProxy(thalesRoyalePrivateMastercopy, "Could not create a Thales Royale Private")
        );
        trp.setZeroExAddressAtInit(zeroExAddress);
        trp.initialize(
            ThalesRoyalePrivate.ThalesRoyalePrivateParameters(
                thalesRoyalePrivateManager,
                creator
            )
        );
        return trp;
    }

    /* ========== SETTERS ========== */
    
    function setThalesRoyalePrivateManager(address _thalesRoyalePrivateManager) external onlyOwner {
        thalesRoyalePrivateManager = _thalesRoyalePrivateManager;
        emit ThalesRoyalePrivateManagerChanged(_thalesRoyalePrivateManager);
    }

    function setThalesRoyalePrivateMastercopy(address _thalesRoyalePrivateMastercopy) external onlyOwner {
        thalesRoyalePrivateMastercopy = _thalesRoyalePrivateMastercopy;
        emit ThalesRoyalePrivateMastercopyChanged(_thalesRoyalePrivateMastercopy);
    }

    function setZeroExAddress(address _zeroExAddress) external {
        require(msg.sender == thalesRoyalePrivateManager, "Only ThalesRoyalePrivate can set the 0x address");
        zeroExAddress = _zeroExAddress;
        emit ZeroExAddressChanged(_zeroExAddress);
    }

    event ThalesRoyalePrivateManagerChanged(address _thalesRoyalePrivateManager);
    event ThalesRoyalePrivateMastercopyChanged(address _binaryOptionMarketMastercopy);
    event ZeroExAddressChanged(address _zeroExAddress);
}
