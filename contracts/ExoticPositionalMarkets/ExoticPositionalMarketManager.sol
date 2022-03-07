pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";
import "./ExoticPositionalMarket.sol";
import "../interfaces/IThalesBonds.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

contract ExoticPositionalMarketManager is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    using SafeMathUpgradeable for uint;

    uint private constant backstopTimeoutDefault = 4 hours;
    uint private constant fixedBondAmountDefault = 100 * 1e18;

    uint public fixedBondAmount;
    uint public backstopTimeout;
    uint public minimumPositioningDuration;
    uint public claimTimeoutDefaultPeriod;
    uint public pDAOResolveTimePeriod;
    uint public safeBoxPercentage;
    uint public creatorPercentage;
    uint public resolverPercentage;
    uint public withdrawalPercentage;
    uint public maxOracleCouncilMembers;

    address public exoticMarketMastercopy;
    address public oracleCouncilAddress;
    address public safeBoxAddress;

    address public thalesBonds;
    address public paymentToken;
    uint public maximumPositionsAllowed;

    mapping(uint => address) public pauserAddress;
    uint public pausersCount;
    mapping(address => uint) public pauserIndex;

    mapping(address => address) public creatorAddress;
    mapping(address => address) public resolverAddress;

    mapping(uint => address) public activeMarkets;
    uint public numOfActiveMarkets;

    function initialize(
        address _owner,
        uint _minimumPositioningDuration,
        address _exoticMarketMastercopy,
        address _paymentToken,
        address _thalesBonds
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        minimumPositioningDuration = _minimumPositioningDuration;
        exoticMarketMastercopy = _exoticMarketMastercopy;
        backstopTimeout = backstopTimeoutDefault;
        maximumPositionsAllowed = 5;
        paymentToken = _paymentToken;
        thalesBonds = _thalesBonds;
        safeBoxPercentage = 1;
        creatorPercentage = 1;
        resolverPercentage = 1;
        withdrawalPercentage = 6;
        claimTimeoutDefaultPeriod = 1 days;
        pDAOResolveTimePeriod = 2 days;
        maxOracleCouncilMembers = 5;
    }

    // Create Exotic market
    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external checkMarketRequirements(_endOfPositioning) nonReentrant {
        require(IERC20(paymentToken).balanceOf(msg.sender) >= fixedBondAmount, "Low token amount for market creation");
        require(
            IERC20(paymentToken).allowance(msg.sender, thalesBonds) >= fixedBondAmount,
            "No allowance. Please approve ticket price allowance"
        );
        require(
            keccak256(abi.encode(_marketQuestion)) != keccak256(abi.encode("")),
            "Invalid market question (empty string)"
        );
        require(keccak256(abi.encode(_marketSource)) != keccak256(abi.encode("")), "Invalid market source (empty string)");
        require(_positionCount == _positionPhrases.length, "Invalid position count with position phrases");
        ExoticPositionalMarket exoticMarket = ExoticPositionalMarket(Clones.clone(exoticMarketMastercopy));

        exoticMarket.initialize(
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionCount,
            _positionPhrases
        );
        creatorAddress[address(exoticMarket)] = msg.sender;
        IThalesBonds(thalesBonds).sendCreatorBondToMarket(address(exoticMarket), msg.sender, fixedBondAmount);
        activeMarkets[numOfActiveMarkets] = address(exoticMarket);
        numOfActiveMarkets = numOfActiveMarkets.add(1);
        emit MarketCreated(address(exoticMarket), _marketQuestion, msg.sender);
    }

    function resolveMarket(address _marketAddress, uint _outcomePosition) external {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        if (creatorAddress[_marketAddress] != msg.sender) {
            require(IERC20(paymentToken).balanceOf(msg.sender) >= fixedBondAmount, "Low token amount for market creation");
            require(
                IERC20(paymentToken).allowance(msg.sender, thalesBonds) >= fixedBondAmount,
                "No allowance. Please approve ticket price allowance"
            );
            IThalesBonds(thalesBonds).sendResolverBondToMarket(_marketAddress, msg.sender, fixedBondAmount);
        }
        resolverAddress[_marketAddress] = msg.sender;
        ExoticPositionalMarket(_marketAddress).resolveMarket(_outcomePosition, msg.sender);
        emit MarketResolved(_marketAddress);
    }

    function cancelMarket(address _marketAddress) external onlyOracleCouncilAndOwner {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        ExoticPositionalMarket(_marketAddress).cancelMarket();
        removeActiveMarket(_marketAddress);
        emit MarketCanceled(_marketAddress);
    }

    function resetMarket(address _marketAddress) external onlyOracleCouncilAndOwner {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        ExoticPositionalMarket(_marketAddress).resetMarket();
        emit MarketReset(_marketAddress);
    }

    function sendMarketBondAmountTo(
        address _market,
        address _recepient,
        uint _amount
    ) external onlyOracleCouncilAndOwner {
        require(_amount > 0, "Invalid amount");
        ExoticPositionalMarket(_market).transferFromBondAmountToRecepient(_recepient, _amount);
    }

    function disputeMarket(address _marketAddress, address _disputor) external onlyOracleCouncil {
        IThalesBonds(thalesBonds).sendDisputorBondToMarket(_marketAddress, _disputor, fixedBondAmount);
        require(!ExoticPositionalMarket(_marketAddress).paused(), "Market is already paused");
        if (!ExoticPositionalMarket(_marketAddress).disputed()) {
            ExoticPositionalMarket(_marketAddress).openDispute();
        }
    }

    function closeDispute(address _marketAddress) external onlyOracleCouncilAndOwner {
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        require(ExoticPositionalMarket(_marketAddress).disputed(), "Market not disputed");
        ExoticPositionalMarket(_marketAddress).closeDispute();
    }

    function getMarketBondAmount(address _market) external view returns (uint) {
        return ExoticPositionalMarket(_market).totalBondAmount();
    }

    function getActiveMarketAddress(uint _index) external view returns (address) {
        return activeMarkets[_index];
    }

    function getActiveMarketIndex(address _marketAddress) public view returns (uint) {
        for (uint i = 0; i < numOfActiveMarkets; i++) {
            if (activeMarkets[i] == _marketAddress) {
                return i;
            }
        }
        return numOfActiveMarkets;
    }

    function isActiveMarket(address _marketAddress) public view returns (bool) {
        return getActiveMarketIndex(_marketAddress) < numOfActiveMarkets;
    }

    function isPauserAddress(address _pauser) external view returns (bool) {
        return pauserIndex[_pauser] > 0;
    }

    // SETTERS ///////////////////////////////////////////////////////////////////////////

    function setFixedBondAmount(uint _fixedBond) external onlyOwner {
        require(_fixedBond > 0, "Invalid bond amount");
        fixedBondAmount = _fixedBond;
        emit NewFixedBondAmount(_fixedBond);
    }

    function setSafeBoxAddress(address _safeBoxAddress) external onlyOwner {
        require(_safeBoxAddress != address(0), "Invalid safeBox address");
        safeBoxAddress = _safeBoxAddress;
        emit NewSafeBoxAddress(_safeBoxAddress);
    }

    function setBackstopTimeout(address _market) external onlyOracleCouncilAndOwner {
        ExoticPositionalMarket(_market).setBackstopTimeout(backstopTimeout);
    }

    function setExoticMarketMastercopy(address _exoticMastercopy) external onlyOwner {
        require(_exoticMastercopy != address(0), "Exotic market invalid");
        exoticMarketMastercopy = _exoticMastercopy;
        emit ExoticMarketMastercopyChanged(_exoticMastercopy);
    }

    function setMinimumPositioningDuration(uint _duration) external onlyOwner {
        minimumPositioningDuration = _duration;
        emit MinimumPositionDurationChanged(_duration);
    }

    function setSafeBoxPercentage(uint _safeBoxPercentage) external onlyOwner {
        safeBoxPercentage = _safeBoxPercentage;
        emit SafeBoxPercentageChanged(_safeBoxPercentage);
    }

    function setCreatorPercentage(uint _creatorPercentage) external onlyOwner {
        creatorPercentage = _creatorPercentage;
        emit CreatorPercentageChanged(_creatorPercentage);
    }

    function setResolverPercentage(uint _resolverPercentage) external onlyOwner {
        resolverPercentage = _resolverPercentage;
        emit ResolverPercentageChanged(_resolverPercentage);
    }

    function setWithdrawalPercentage(uint _withdrawalPercentage) external onlyOwner {
        withdrawalPercentage = _withdrawalPercentage;
        emit WithdrawalPercentageChanged(_withdrawalPercentage);
    }

    function setPDAOResolveTimePeriod(uint _pDAOResolveTimePeriod) external onlyOwner {
        pDAOResolveTimePeriod = _pDAOResolveTimePeriod;
        emit setPDAOResolveTimePeriodChanged(_pDAOResolveTimePeriod);
    }

    function setOracleCouncilAddress(address _councilAddress) external onlyOwner {
        require(_councilAddress != address(0), "Invalid address");
        oracleCouncilAddress = _councilAddress;
        emit NewOracleCouncilAddress(_councilAddress);
    }

    function setMaximumPositionsAllowed(uint _maximumPositionsAllowed) external onlyOwner {
        require(_maximumPositionsAllowed > 2, "Invalid Maximum positions allowed");
        maximumPositionsAllowed = _maximumPositionsAllowed;
        emit NewMaximumPositionsAllowed(_maximumPositionsAllowed);
    }

    function setMaxOracleCouncilMembers(uint _maxOracleCouncilMembers) external onlyOwner {
        require(_maxOracleCouncilMembers > 3, "Invalid Maximum Oracle Council members. Number too low");
        maxOracleCouncilMembers = _maxOracleCouncilMembers;
        emit NewMaxOracleCouncilMembers(_maxOracleCouncilMembers);
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        require(_paymentToken != address(0), "Invalid address");
        paymentToken = _paymentToken;
        emit NewPaymentToken(_paymentToken);
    }

    function setThalesBonds(address _thalesBonds) external onlyOwner {
        require(_thalesBonds != address(0), "Invalid address");
        thalesBonds = _thalesBonds;
        emit NewThalesBonds(_thalesBonds);
    }

    function addPauserAddress(address _pauserAddress) external onlyOracleCouncilAndOwner {
        require(_pauserAddress != address(0), "Invalid address");
        require(pauserIndex[_pauserAddress] == 0, "Address already exists as pauser");
        pausersCount = pausersCount.add(1);
        pauserIndex[_pauserAddress] = pausersCount;
        pauserAddress[pausersCount] = _pauserAddress;
        emit PauserAddressAdded(_pauserAddress);
    }

    function removePauserAddress(address _pauserAddress) external onlyOracleCouncilAndOwner {
        require(_pauserAddress != address(0), "Invalid address");
        require(pauserIndex[_pauserAddress] != 0, "Invalid pauser address, not exists as pauser");
        pauserAddress[pauserIndex[_pauserAddress]] = pauserAddress[pausersCount];
        pauserIndex[pauserAddress[pausersCount]] = pauserIndex[_pauserAddress];
        pausersCount = pausersCount.sub(1);
        pauserIndex[_pauserAddress] = 0;
        emit PauserAddressRemoved(_pauserAddress);
    }

    // INTERNAL FUNCTIONS

    function removeActiveMarket(address _marketAddress) internal {
        activeMarkets[getActiveMarketIndex(_marketAddress)] = activeMarkets[numOfActiveMarkets.sub(1)];
        numOfActiveMarkets = numOfActiveMarkets.sub(1);
        activeMarkets[numOfActiveMarkets] = address(0);
    }

    modifier checkMarketRequirements(uint _endOfPositioning) {
        require(exoticMarketMastercopy != address(0), "No ExoticMarket mastercopy present. Please update the mastercopy");
        require(thalesBonds != address(0), "Invalid Thales bond address");
        require(
            _endOfPositioning >= block.timestamp.add(minimumPositioningDuration),
            "Posiitioning period too low. Increase the endOfPositioning"
        );
        _;
    }

    event MinimumPositionDurationChanged(uint duration);
    event MinimumMarketMaturityDurationChanged(uint duration);
    event ExoticMarketMastercopyChanged(address _exoticMastercopy);
    event MarketCreated(address marketAddress, string marketQuestion, address marketOwner);
    event MarketResolved(address marketAddress);
    event MarketCanceled(address marketAddress);
    event MarketReset(address marketAddress);
    event NewOracleCouncilAddress(address oracleCouncilAddress);
    event NewFixedBondAmount(uint fixedBond);
    event NewSafeBoxAddress(address safeBox);
    event NewMaximumPositionsAllowed(uint maximumPositionsAllowed);
    event NewPaymentToken(address paymentTokenAddress);
    event NewThalesBonds(address thalesBondsAddress);
    event ResolverPercentageChanged(uint resolverPercentage);
    event CreatorPercentageChanged(uint creatorPercentage);
    event SafeBoxPercentageChanged(uint safeBoxPercentage);
    event WithdrawalPercentageChanged(uint withdrawalPercentage);
    event setPDAOResolveTimePeriodChanged(uint pDAOResolveTimePeriod);
    event NewMaxOracleCouncilMembers(uint maxOracleCouncilMembers);
    event PauserAddressAdded(address pauserAddress);
    event PauserAddressRemoved(address pauserAddress);
    event MarketPaused(address marketAddress);

    modifier onlyOracleCouncil() {
        require(msg.sender == oracleCouncilAddress, "Not OracleCouncil address");
        require(oracleCouncilAddress != address(0), "Not OracleCouncil address. Please update valid Oracle address");
        _;
    }
    modifier onlyOracleCouncilAndOwner() {
        require(msg.sender == oracleCouncilAddress || msg.sender == owner, "Not OracleCouncil Address or Owner address");
        if (msg.sender != owner) {
            require(oracleCouncilAddress != address(0), "Not OracleCouncil address. Please update valid Oracle address");
        }
        _;
    }
}