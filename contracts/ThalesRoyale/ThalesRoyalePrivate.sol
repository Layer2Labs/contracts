pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Inheritance
import "synthetix-2.50.4-ovm/contracts/MinimalProxyFactory.sol";
import "../OwnedWithInit.sol";
import "../interfaces/IThalesRoyalePrivate.sol";

contract ThalesRoyalePrivate is MinimalProxyFactory, OwnedWithInit, IThalesRoyalePrivate {

    struct ThalesRoyalePrivateParameters {
        address owner;
        address creator;
    }

    /* ========== STATE VARIABLES ========== */
    address public zeroExAddress;
    
    uint internal zeroInitCounter;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(ThalesRoyalePrivateParameters calldata _parameters) external {
        require(!initialized, "Thales Royale already initialized");
        initialized = true;
        initOwner(_parameters.owner);
    }
    

    function setZeroExAddressAtInit(address _zeroExAddress) external {
        require(zeroInitCounter == 0, "0x already set at Init");
        zeroInitCounter = 9;
        zeroExAddress = _zeroExAddress;
    }

    function setZeroExAddress(address _zeroExAddress) external onlyOwner {
        zeroExAddress = _zeroExAddress;
    }
}