// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./MatchMaking.sol";

contract GlickoRating is MatchMaking {
    event NewMatch(address indexed p1, address indexed p2);

    mapping(address => PlayerRating) glickoRating;

    struct PlayerRating {
        uint256 rating;
        uint256 RD;
        uint256 volatility;
    }

    address[] private inQueue;

    constructor(address addr) MatchMaking(addr) {}

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

    function confirmMatch(
        Match memory m,
        Sig memory p1sig,
        Sig memory p2sig
    ) public override {}

    function alterRanking() public override onlyOwner {}
}
