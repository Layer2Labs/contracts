// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITherundownConsumer {

    // view functions
    function isSupportedSport(uint _sportId) external view returns (bool);
    function isSupportedMarketType(string memory _market) external view returns (bool);

    // write functions
    function fulfillGamesCreated(bytes32 _requestId, bytes[] memory _games, uint _sportsId) external;
    function fulfillGamesResolved(bytes32 _requestId, bytes[] memory _games, uint _sportsId) external;
}