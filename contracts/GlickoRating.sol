// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./RatingSystem.sol";

contract GlickoRating is RatingSystem {
    
    mapping(address => PlayerRating) glickoRating;

    struct PlayerRating {
        uint256 rating;
        uint256 RD;
        uint256 volatility;
    }

    address[] private inQueue;

    constructor(address addr) RatingSystem(addr) {}

    function writeMatchResult(Match memory m, MatchResult result)
        public
        override
        onlyGameContract
    {}

    // function joinQueue() public override {}

    // function leaveQueue() public override {}

    // function evaluateMatches() public override {
    //     for (uint256 i = 0; i < inQueue.length; i++) {
    //         address player = inQueue[i];
    //         PlayerRating storage rating = glickoRating[player];
    //     }
    // }

    function createMatch(
        Match memory m,
        Sig memory pAsig,
        Sig memory pBsig
    ) public override {}
}
