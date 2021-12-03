pragma solidity ^0.5.16;

// Inheritance
import "../interfaces/IThalesRoyalePrivateManager.sol";
import "synthetix-2.50.4-ovm/contracts/Owned.sol";
import "synthetix-2.50.4-ovm/contracts/Pausable.sol";

// Libraries
import "synthetix-2.50.4-ovm/contracts/AddressSetLib.sol";
import "synthetix-2.50.4-ovm/contracts/SafeDecimalMath.sol";

// Internal references
import "./ThalesRoyalePrivate.sol";
import "./ThalesRoyalePrivateFactory.sol";
import "../interfaces/IThalesRoyalePrivate.sol";

contract ThalesRoyalePrivateManager is Owned, Pausable, IThalesRoyalePrivateManager {

     /* ========== LIBRARIES ========== */

    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    bool public royaleCreationEnabled = true;

    AddressSetLib.AddressSet internal _activeRoyales;
    AddressSetLib.AddressSet internal _maturedRoyales;

    address public thalesRoyalePrivateMarketFactory;
    
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner
    ) public Owned(_owner) Pausable() {
        owner = _owner;
    }


    /* ---------- Royale Lifecycle ---------- */

    function createRoyale(
    )
        external
        notPaused
        returns (
            IThalesRoyalePrivate 
        )
    {
        require(royaleCreationEnabled, "Royale creation is disabled");

        ThalesRoyalePrivate royale = ThalesRoyalePrivateFactory(thalesRoyalePrivateMarketFactory).createRoyale(
            msg.sender
        );

        _activeRoyales.add(address(royale));

        emit RoyaleCreated(
            address(royale)
        );

        return royale;
    }

    /* ========== EVENTS ========== */

    event RoyaleCreated(
        address royale
    );
}